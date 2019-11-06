defmodule StoreHall.ItemFilter do
  import Ecto.Query, warn: false

  alias StoreHall.FilterableQuery

  def search_filter(query, nil), do: query

  def search_filter(query, %{"filter" => search_terms}) do
    dynamic =
      search_terms
      |> Map.keys()
      |> Enum.reduce(true, fn search_key, acc ->
        try do
          filter(String.to_existing_atom(search_key), acc, Map.get(search_terms, search_key))
        rescue
          _ -> acc
        end
      end)

    query
    |> where(^dynamic)
  end

  def search_filter(query, _), do: query

  defp filter_q(nil, dynamic), do: dynamic
  defp filter_q("", dynamic), do: dynamic

  defp filter_q(search_string, dynamic) when is_binary(search_string) and search_string == "",
    do: dynamic

  defp filter_q(search_string, dynamic) when is_binary(search_string) do
    FilterableQuery.clean_dynamic(
      :and,
      dynamic,
      dynamic(
        [u],
        ilike(u.name, ^"%#{search_string}%") or ilike(u.user_id, ^"%#{search_string}%")
      )
    )
  end

  defp filter_q(list, dynamic) when is_list(list) do
    list
    |> Enum.reduce(dynamic, fn search, acc ->
      filter_q(search, acc)
    end)
  end

  defp filter(:q, dynamic, list) when is_list(list) do
    list
    |> filter_q(dynamic)
  end

  defp filter(:q, dynamic, string) when is_binary(string) do
    string
    |> String.split(" ")
    |> filter_q(dynamic)
  end

  defp filter(:q, dynamic, _), do: dynamic

  defp filter(:price, dynamic, %{"min" => min_price}) do
    case Float.parse(min_price) do
      {0.0, _} ->
        dynamic

      {min_price, _} when is_float(min_price) ->
        FilterableQuery.construct_where_fragment(
          dynamic,
          %{
            gte: %{
              field: ["price"],
              value: min_price
            }
          }
        )

      _ ->
        dynamic
    end
  end

  defp filter(:price, dynamic, %{"max" => max_price}) do
    case Float.parse(max_price) do
      {5.0, _} ->
        dynamic

      {max_price, _} when is_float(max_price) ->
        FilterableQuery.construct_where_fragment(
          dynamic,
          %{
            lte: %{
              field: ["price"],
              value: max_price
            }
          }
        )

      _ ->
        dynamic
    end
  end

  defp filter(:price, dynamic, _), do: dynamic

  defp filter(:rating, dynamic, %{"min" => min_rating}) do
    case Float.parse(min_rating) do
      {0.0, _} ->
        dynamic

      {min_rating, _} when is_float(min_rating) ->
        FilterableQuery.construct_where_fragment(
          dynamic,
          %{
            gte: %{
              field: ["rating", "score"],
              value: min_rating
            }
          }
        )

      _ ->
        dynamic
    end
  end

  defp filter(:rating, dynamic, %{"max" => max_rating}) do
    case Float.parse(max_rating) do
      {5.0, _} ->
        dynamic

      {max_rating, _} when is_float(max_rating) ->
        FilterableQuery.construct_where_fragment(
          dynamic,
          %{
            lte: %{
              field: ["rating", "score"],
              value: max_rating
            }
          }
        )

      _ ->
        dynamic
    end
  end

  defp filter(:rating, dynamic, _), do: dynamic

  defp filter(:tags, dynamic, value) do
    FilterableQuery.construct_where_fragment(
      dynamic,
      %{
        in: %{
          field: ["tags"],
          value: value
        }
      }
    )
  end

  defp filter(:merchant, dynamic, value) when value == [""], do: dynamic

  defp filter(:merchant, dynamic, value) do
    FilterableQuery.clean_dynamic(:and, dynamic, dynamic([u], u.user_id in ^value))
  end

  defp filter(:"with-image", dynamic, _value) do
    FilterableQuery.construct_where_fragment(
      dynamic,
      %{
        length_at_least: %{
          field: ["images"],
          value: 1
        }
      }
    )
  end

  # example value: {"gte": {"field": "rating, core", "value": 4}}
  # example url params mimicin with_image filter &filter[length_at_least][field][]=images&filter[length_at_least][value]=1
  defp filter(:"custom-filters", dynamic, value) do
    try do
      FilterableQuery.construct_where_fragment(
        dynamic,
        keys_to_existing_atom(value |> Jason.decode() |> elem(1))
      )
    rescue
      _ -> dynamic
    end
  end

  defp filter(_, dynamic, _), do: dynamic

  defp keys_to_existing_atom(value) when is_map(value) do
    for {key, val} <- value,
        into: %{},
        do: {String.to_existing_atom(key), keys_to_existing_atom(val)}
  end

  defp keys_to_existing_atom(value) when is_list(value) do
    value |> Enum.map(fn map -> keys_to_existing_atom(map) end)
  end

  defp keys_to_existing_atom(value), do: value
end
