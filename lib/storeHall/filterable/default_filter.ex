defmodule StoreHall.DefaultFilter do
  import Ecto.Query, warn: false

  alias StoreHall.Users

  @accepted_orders [
    :asc,
    :asc_nulls_last,
    :asc_nulls_first,
    :desc,
    :desc_nulls_last,
    :desc_nulls_first
  ]

  @accepted_fields [:id, :inserted_at, :updated_at, :name]

  def sort_filter(query, nil), do: query |> order_by([{:asc, :inserted_at}])
  def sort_filter(query, -1), do: query |> order_by([{:asc, :inserted_at}])

  def sort_filter(query, %{"filter" => %{"sort" => value}}) do
    value
    |> String.split(";")
    |> Enum.reduce(query, fn field, q ->
      with {:ok, split_field} <- {:ok, String.split(field, ":")},
           {:ok, field_atom} <-
             {:ok,
              split_field
              |> hd
              |> to_existing_atom(:inserted_at)
              |> to_accepted_fields()},
           {:ok, order_atom} <-
             {:ok,
              split_field
              |> Enum.reverse()
              |> hd
              |> to_existing_atom(:asc)
              |> to_accepted_orders()} do
        q |> order_by([{^order_atom, ^field_atom}])
      end
    end)
  end

  def sort_filter(query, _), do: query

  def paging_filter(query, params) do
    page = parse_int(params["page"], 1)
    page_size = parse_int(params["page-size"], 10)
    offset = page_size * (page - 1)

    query
    |> limit([_], ^page_size)
    |> offset([_], ^offset)
  end

  def order_first_for(query, nil), do: query
  def order_first_for(query, -1), do: query

  def order_first_for(query, current_user_id) do
    query
    |> order_by([c], [
      fragment("CASE WHEN ? = ? THEN 0 ELSE 1 END ASC", c.author_id, ^current_user_id)
    ])
  end

  def min_author_rating_filter(query, nil), do: query
  def min_author_rating_filter(query, -1), do: query

  def min_author_rating_filter(query, current_user_id) do
    Users.get_user_with_settings(current_user_id)
    |> case do
      nil ->
        query

      user ->
        min_rating = user.settings["filters"]["show_with_min_rating"]

        dynamic =
          dynamic(
            [c, a: u],
            fragment(
              " (?.details->'rating'->>'score') IS NULL or  (?.details->'rating'->>'score')::decimal >= ? ",
              u,
              u,
              ^min_rating
            )
          )

        query
        |> join(:left, [c], u in assoc(c, :author), as: :a)
        |> where(^dynamic)
    end
  end

  def hide_guests_filter(query, nil), do: query
  def hide_guests_filter(query, -1), do: query

  def hide_guests_filter(query, current_user_id) do
    Users.get_user_with_settings(current_user_id)
    |> case do
      nil ->
        query

      user ->
        hide_guests = user.settings["filters"]["hide_guests"]

        if hide_guests do
          query
          |> where([c], not is_nil(c.author_id))
        else
          query
        end
    end
  end

  defp parse_int(nil, default), do: default
  defp parse_int(x, default) when is_binary(x), do: fetch_int(Integer.parse(x), default)

  defp fetch_int({number, ""}, _default) when is_integer(number), do: number
  defp fetch_int(:error, default), do: default

  defp to_existing_atom(string, default) do
    try do
      string |> String.to_existing_atom()
    rescue
      _ -> default
    end
  end

  defp to_accepted_fields(atom) when atom in @accepted_fields, do: atom
  defp to_accepted_fields(_string), do: :id
  def accepted_fields(), do: @accepted_fields
  defp to_accepted_orders(atom) when atom in @accepted_orders, do: atom
  defp to_accepted_orders(_string), do: :asc
  def accepted_orders(), do: @accepted_orders
end
