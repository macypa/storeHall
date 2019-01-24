defmodule StoreHall.Items.ItemFilterable do
  use Filterable.DSL
  use Filterable.Ecto.Helpers
  import Ecto.Query, warn: false

  paginateable(per_page: 10)

  @options param: [:field, :order],
           default: [field: :id, order: :asc],
           cast_errors: true
  filter sort(query, %{field: fields, order: order}, _conn) do
    String.split(fields, ",")
    |> Enum.reduce(query, fn field, q ->
      field_atom =
        case field do
          "id" -> :id
          "name" -> :name
          "user_id" -> :user_id
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
