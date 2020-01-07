defmodule StoreHall.UserFilter do
  import Ecto.Query, warn: false

  def search_filter(query, %{"filter" => %{"q" => value}}) do
    query
    |> where(
      [u],
      ilike(u.name, ^"%#{value}%")
    )
  end

  def search_filter(query, _), do: query
end
