defmodule StoreHall.UserFilter do
  import Ecto.Query, warn: false

  import StoreHall.DefaultFilter

  def search_filter(query, %{"filter" => %{"q" => value}}) do
    query
    |> where(
      [u],
      ilike(u.first_name, ^"%#{value}%") or
        ilike(u.last_name, ^"%#{value}%")
    )
  end

  def search_filter(query, _), do: query
end
