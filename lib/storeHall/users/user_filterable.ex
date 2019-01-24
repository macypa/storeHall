defmodule StoreHall.Users.UserFilterable do
  use Filterable.DSL
  use Filterable.Ecto.Helpers
  import Ecto.Query, warn: false

  paginateable(per_page: 10)

  @options param: [:sort, :order],
           default: [sort: "id", order: :desc],
           cast_errors: true
  filter sort(query, %{sort: fields, order: order}, _conn) do
    String.split(fields, ",")
    |> Enum.reduce(query, fn field, q ->
      field_atom =
        case field do
          "id" -> :id
          "email" -> :email
          "first_name" -> :first_name
          "last_name" -> :last_name
          _ -> :id
        end

      order_atom =
        case order do
          "asc" -> :asc
          "desc" -> :desc
          _ -> :asc
        end

      q |> order_by([{^order_atom, ^field_atom}])
    end)
  end
end
