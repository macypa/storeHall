defmodule StoreHall.DefaultFilter do
  import StoreHall.FilterAcceptedOptions
  import Ecto.Query, warn: false
  alias StoreHall.Users

  @accepted_fields [:id, :inserted_at, :updated_at, :name]
  def sort_filter(query, nil), do: query |> order_by([{:asc, :inserted_at}])
  def sort_filter(query, -1), do: query |> order_by([{:asc, :inserted_at}])

  def sort_filter(query, %{"filter" => %{"sort" => value}}) do
    value
    |> String.split(",", trim: true)
    |> Enum.reduce(query, fn field, q ->
      split_field = field |> String.split(":", trim: true)
      field_atom = split_field |> hd

      order_atom =
        split_field |> Enum.reverse() |> hd |> to_existing_atom(:asc) |> to_accepted_orders(:asc)

      @accepted_fields
      |> Enum.find(field_atom, fn accepted_field ->
        to_existing_atom(field_atom, field_atom) == accepted_field
      end)
      |> case do
        field when is_atom(field) ->
          q
          |> order_by([{^order_atom, ^field}])

        details_field ->
          order_by_details_field(q, details_field, order_atom)
      end
    end)
  end

  def sort_filter(query, _), do: query

  def paging_filter(query, params, default_page_size \\ 5)

  def paging_filter(query, params, default_page_size) do
    parse_int(params["page-size"], default_page_size)
    |> case do
      -1 ->
        query

      page_size ->
        page = parse_int(params["page"], 1)
        offset = page_size * (page - 1)

        query
        |> limit([_], ^page_size)
        |> offset([_], ^offset)
    end
  end

  def order_first_for(query, nil), do: query
  def order_first_for(query, -1), do: query

  def order_first_for(query, current_user_id) do
    query
    |> order_by([c], [
      fragment("CASE WHEN ? = ? THEN 0 ELSE 1 END ASC", c.author_id, ^current_user_id)
    ])
  end

  def show_with_min_rating(query, _author_user, nil), do: query
  def show_with_min_rating(query, _author_user, -1), do: query

  def show_with_min_rating(query, author_user, current_user_id) do
    Users.get_user_with_settings(current_user_id)
    |> case do
      nil ->
        query

      user ->
        min_rating = user.settings["filters"]["show_with_min_rating"]

        case Integer.parse(to_string(min_rating)) do
          :error ->
            query

          {min_rating, ""} ->
            dynamic =
              dynamic(
                [c, a: u],
                fragment(
                  " ((?.details->'rating'->>'score') IS NULL or (?.details->'rating'->>'score')::numeric >= ?) and ((?.details->'rating'->>'score') IS NULL or (?.details->'rating'->>'score')::numeric >= ?) ",
                  u,
                  u,
                  ^min_rating,
                  c,
                  c,
                  ^min_rating
                )
              )

            case author_user do
              :author ->
                query
                |> join(:left, [c], u in assoc(c, :author), as: :a)
                |> where(^dynamic)

              :user ->
                query
                |> join(:left, [c], u in assoc(c, :user), as: :a)
                |> where(^dynamic)

              _ ->
                query
            end
        end
    end
  end

  def show_with_max_alerts(query, nil), do: query
  def show_with_max_alerts(query, -1), do: query

  def show_with_max_alerts(query, current_user_id) do
    Users.get_user_with_settings(current_user_id)
    |> case do
      nil ->
        query

      user ->
        max_alerts = user.settings["filters"]["show_with_max_alerts"]

        case max_alerts do
          "" ->
            query

          _ ->
            query
            |> having([c, ra: r], count(r.id) <= ^max_alerts)
        end
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
  defp parse_int(x, _default) when is_integer(x), do: x
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

  defmacro order_by_details_field_fragment(query, field_frag) do
    quote do
      unquote(query)
      |> order_by([c], fragment(unquote(field_frag), c))
    end
  end

  defmacro order_by_details_field_fragment(query, field_frag, feature) do
    quote do
      unquote(query)
      |> order_by([c], fragment(unquote(field_frag), c, ^unquote(feature)))
    end
  end

  defp order_by_details_field(query, "price", :desc),
    do: order_by_details_field_fragment(query, "(?.details->>'price')::numeric DESC NULLS LAST")

  defp order_by_details_field(query, "discount", :desc),
    do:
      order_by_details_field_fragment(query, "(?.details->>'discount')::numeric DESC NULLS LAST")

  defp order_by_details_field(query, "rating", :desc),
    do:
      order_by_details_field_fragment(
        query,
        "(?.details->'rating'->>'score')::numeric DESC NULLS LAST"
      )

  defp order_by_details_field(query, "expiration", :desc),
    do:
      order_by_details_field_fragment(
        query,
        "(?.details->>'expiration')::timestamp DESC NULLS FIRST"
      )

  defp order_by_details_field(query, "feature_" <> feature, :desc),
    do:
      order_by_details_field_fragment(query, "?.details->'features'->>? DESC NULLS LAST", feature)

  defp order_by_details_field(query, "price", _),
    do: order_by_details_field_fragment(query, "(?.details->>'price')::numeric")

  defp order_by_details_field(query, "discount", _),
    do: order_by_details_field_fragment(query, "(?.details->>'discount')::numeric")

  defp order_by_details_field(query, "rating", _),
    do: order_by_details_field_fragment(query, "(?.details->'rating'->>'score')::numeric")

  defp order_by_details_field(query, "expiration", _),
    do: order_by_details_field_fragment(query, "(?.details->>'expiration')::timestamp")

  defp order_by_details_field(query, "feature_" <> feature, _),
    do: order_by_details_field_fragment(query, "?.details->'features'->>?", feature)

  defp order_by_details_field(query, "mail_credits_ask", :desc),
    do:
      order_by_details_field_fragment(
        query,
        "(?.marketing_info->>'mail_credits_ask')::numeric DESC NULLS LAST"
      )

  defp order_by_details_field(query, "mail_credits_ask", _),
    do: order_by_details_field_fragment(query, "(?.marketing_info->>'mail_credits_ask')::numeric")

  defp order_by_details_field(query, "last_activity", :desc),
    do:
      order_by_details_field_fragment(
        query,
        "(?.marketing_info->>'last_activity')::timestamp DESC NULLS LAST"
      )

  defp order_by_details_field(query, "last_activity", _),
    do: order_by_details_field_fragment(query, "(?.marketing_info->>'last_activity')::timestamp")
end
