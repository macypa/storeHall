defmodule StoreHall.ItemFilter do
  import Ecto.Query, warn: false

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

  defp filter(:q, dynamic, map) when is_map(map) do
    map
    |> Enum.reduce(dynamic, fn search, acc ->
      dynamic(
        [u],
        ^acc and (ilike(u.name, ^"%#{search}%") or ilike(u.user_id, ^"%#{search}%"))
      )
    end)
  end

  defp filter(:q, dynamic, string) when is_binary(string) do
    string
    |> String.split(" ")
    |> Enum.reduce(dynamic, fn search, acc ->
      dynamic(
        [u],
        ^acc and (ilike(u.name, ^"%#{search}%") or ilike(u.user_id, ^"%#{search}%"))
      )
    end)
  end

  defp filter(:q, dynamic, _), do: dynamic

  defp filter(:rating, dynamic, %{"min" => min_rating}) do
    case Float.parse(min_rating) do
      {0.0, _} ->
        dynamic

      {min_rating, _} when is_float(min_rating) ->
        dynamic(
          [u],
          ^dynamic and fragment(" (details->'rating'->>'score')::float >= ? ", ^min_rating)
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
        dynamic(
          [u],
          ^dynamic and fragment(" (details->'rating'->>'score')::float <= ? ", ^max_rating)
        )

      _ ->
        dynamic
    end
  end

  defp filter(:rating, dynamic, _), do: dynamic

  defp filter(:tags, dynamic, value) do
    dynamic(
      [u],
      ^dynamic and fragment(" (details -> 'tags' \\?| ?) ", ^value)
    )
  end

  defp filter(:merchant, dynamic, value) do
    case value do
      [""] -> dynamic
      value -> dynamic([u], ^dynamic and u.user_id in ^value)
    end
  end

  defp filter(:"with-image", dynamic, _value) do
    dynamic(
      [u],
      ^dynamic and fragment(" jsonb_array_length(details -> 'images') > 0 ")
    )
  end

  defp filter(_Key, dynamic, _value), do: dynamic
end
