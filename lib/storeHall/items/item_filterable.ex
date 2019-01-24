defmodule StoreHall.Items.ItemFilterable do
  use Filterable.DSL
  use Filterable.Ecto.Helpers
  import Ecto.Query, warn: false

  paginateable(per_page: 10)

  @options param: :q
  filter search(query, search_terms, _conn) do
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

  @options param: [:sort, :order],
           default: [sort: "id", order: :desc],
           cast_errors: true
  filter sort(query, %{sort: fields, order: order}, _conn) do
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
