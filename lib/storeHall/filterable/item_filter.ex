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
            try do
              filter(String.to_existing_atom(search_key), acc, Map.get(search_terms, search_key))
            rescue
              _ -> acc
            end
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

  defp filter(:rating, dynamic, %{"min" => value}) do
    case Float.parse(value) do
      {0.0, ""} ->
        dynamic

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
