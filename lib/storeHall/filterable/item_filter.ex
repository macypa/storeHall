defmodule StoreHall.ItemFilter do
  import Ecto.Query, warn: false

  import StoreHall.DefaultFilter
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

  defp filter_q(map, dynamic) do
    map
    |> Enum.reduce(dynamic, fn search, acc ->
      case search do
        "" ->
          dynamic

        search ->
          clean_dynamic(
            :and,
            acc,
            dynamic(
              [u],
              ilike(u.name, ^"%#{search}%") or ilike(u.user_id, ^"%#{search}%")
            )
          )
      end
    end)
  end

  defp filter(:q, dynamic, map) when is_map(map) do
    map
    |> filter_q(dynamic)
  end

  defp filter(:q, dynamic, string) when is_binary(string) do
    string
    |> String.split(" ")
    |> filter_q(dynamic)
  end

  defp filter(:q, dynamic, _), do: dynamic

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
        have_one: %{
          field: ["tags"],
          value: value
        }
      }
    )
  end

  defp filter(:merchant, dynamic, value) do
    case value do
      [""] ->
        dynamic

      value ->
        clean_dynamic(:and, dynamic, dynamic([u], u.user_id in ^value))
    end
  end

  defp filter(:"with-image", dynamic, _value) do
    FilterableQuery.construct_where_fragment(
      dynamic,
      %{
        or: [
          length_at_least: %{
            field: ["images"],
            value: 0
          }
        ]
      }
    )
  end

  defp filter(_Key, dynamic, _value), do: dynamic
end
