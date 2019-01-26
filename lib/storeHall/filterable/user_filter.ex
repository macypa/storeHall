defmodule StoreHall.UserFilter do
  import Ecto.Query, warn: false

  def search_filter(query, conn) do
    value = conn.params["filter"]["q"]

    value
    |> case do
      nil ->
        query

      value ->
        query
        |> where([u], ilike(u.first_name, ^"%#{value}%"))
        |> or_where([u], ilike(u.last_name, ^"%#{value}%"))
    end
  end
end
