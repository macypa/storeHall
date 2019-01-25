defmodule StoreHall.DefaultFilterable do
  import Ecto.Query, warn: false

  def sort_filter(query, value, _conn) do
    String.split(value, ";")
    |> Enum.reduce(query, fn field, q ->
      field_atom =
        String.split(field, ":")
        |> hd
        |> case do
          "id" -> :id
          "name" -> :name
          "user_id" -> :user_id
          "email" -> :email
          "first_name" -> :first_name
          "last_name" -> :last_name
          _ -> :id
        end

      order_atom =
        String.split(field, ":")
        |> tl
        |> hd
        |> case do
          "asc" -> :asc
          "desc" -> :desc
          _ -> :asc
        end

      q |> order_by([{^order_atom, ^field_atom}])
    end)
  end
end
