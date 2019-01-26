defmodule StoreHall.ItemFilter do
  import Ecto.Query, warn: false

  def search_filter(query, conn) do
    search_terms = conn.params["filter"]

    search_terms
    |> case do
      nil ->
        query

      search_terms ->
        dynamic =
          search_terms
          |> Map.keys()
          |> Enum.reduce(true, fn search_key, acc ->
            filter(search_key, acc, Map.get(search_terms, search_key))
          end)

        query
        |> where(^dynamic)
    end
  end

  defp filter(:q, dynamic, value) do
    value
    |> case do
      map when is_map(map) ->
        map
        |> Enum.reduce(dynamic, fn search, acc ->
          dynamic(
            [u],
            ^acc and (ilike(u.name, ^"%#{search}%") or ilike(u.user_id, ^"%#{search}%"))
          )
        end)

      string when is_binary(string) ->
        string
        |> String.split(" ")
        |> Enum.reduce(dynamic, fn search, acc ->
          dynamic(
            [u],
            ^acc and (ilike(u.name, ^"%#{search}%") or ilike(u.user_id, ^"%#{search}%"))
          )
        end)

      _ ->
        dynamic
    end
  end

  defp filter(:rating, dynamic, %{score: %{:min => value}}) do
    case Float.parse(value) do
      {min_rating, ""} ->
        dynamic(
          [u],
          ^dynamic and fragment(" (details->'rating'->>'score')::float >= ? ", ^min_rating)
        )

      _ ->
        dynamic
    end
  end

  defp filter(:tags, dynamic, value) do
    value
    |> Enum.reduce(dynamic, fn tag, acc ->
      dynamic(
        [u],
        ^acc and fragment(" (details -> 'tags' \\? ?) ", ^tag)
      )
    end)
  end

  defp filter(_Key, dynamic, _value), do: dynamic
end
