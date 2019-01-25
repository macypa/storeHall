defmodule StoreHall.UserFilterable do
  import Ecto.Query, warn: false

  def search_filter(query, value, _conn) do
    query
    |> where([u], ilike(u.first_name, ^"%#{value}%"))
    |> or_where([u], ilike(u.last_name, ^"%#{value}%"))
  end
end
