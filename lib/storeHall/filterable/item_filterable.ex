defmodule StoreHall.ItemFilterable do
  import Ecto.Query, warn: false

  def search_filter(query, search_terms, _conn) do
    dynamic =
      String.split(search_terms, " ")
      |> Enum.reduce(true, fn search, acc ->
        dynamic(
          [u],
          ^acc and (ilike(u.name, ^"%#{search}%") or ilike(u.user_id, ^"%#{search}%"))
        )
      end)

    query
    |> where(^dynamic)
  end
end
