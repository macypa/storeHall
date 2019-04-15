defmodule StoreHall.DefaultFilter do
  import Ecto.Query, warn: false

  @accepted_orders [
    :asc,
    :asc_nulls_last,
    :asc_nulls_first,
    :desc,
    :desc_nulls_last,
    :desc_nulls_first
  ]

  @accepted_fields [:id, :inserted_at, :updated_at, :name, :user_id, :first_name, :last_name]

  def sort_filter(query, params) do
    value = get_in(params, ["filter", "sort"])

    value
    |> case do
      nil ->
        query |> order_by([{:desc, :inserted_at}])

      "" ->
        query |> order_by([{:desc, :inserted_at}])

      value ->
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
  end

  def paging_filter(query, params) do
    page = parse_int(params["page"], 1)
    page_size = parse_int(params["page-size"], 10)
    offset = page_size * (page - 1)

    query
    |> limit([_], ^page_size)
    |> offset([_], ^offset)
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
