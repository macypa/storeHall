defmodule StoreHall.Users.UserFilterable do
  use Filterable.DSL
  use Filterable.Ecto.Helpers
  import Ecto.Query, warn: false

  paginateable(per_page: 10)

  @options param: [:sort, :order],
           default: [sort: :id, order: :asc],
           cast_errors: true
  filter search(query, %{sort: field, order: order}, _conn) do
    String.split(field, ",")
    |> Enum.reduce(query, fn f, q ->
      f_atom =
        case f do
          "id" -> :id
          "email" -> :email
          "first_name" -> :first_name
          "last_name" -> :last_name
          _ -> :id
        end

      o_atom =
        case order do
          "asc" -> :asc
          "desc" -> :desc
          _ -> :asc
        end

      q |> order_by([{^o_atom, ^f_atom}])
    end)
  end
end
