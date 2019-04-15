defmodule StoreHall.UserFilter do
  import Ecto.Query, warn: false

  def search_filter(query, params) do
    value = get_in(params, ["filter", "q"])

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
