defmodule StoreHall.DefaultFilter do
  import Ecto.Query, warn: false

  @accepted_orders [
    :asc,
    :asc_nulls_last,
    :asc_nulls_first,
    :desc,
    :desc_nulls_last,
    :desc_nulls_first
  ]

  @accepted_fields [:id, :name, :user_id, :first_name, :last_name]

  def sort_filter(query, conn) do
    value = conn.params["sort"]

    value
    |> case do
      nil ->
        query

      value ->
        value
        |> String.split(";")
        |> Enum.reduce(query, fn field, q ->
          with {:ok, split_field} <- {:ok, String.split(field, ":")},
               {:ok, field_atom} <-
                 {:ok,
                  split_field
                  |> hd
                  |> to_existing_atom(:id)
                  |> to_atom_fields()},
               {:ok, order_atom} <-
                 {:ok,
                  split_field
                  |> Enum.reverse()
                  |> hd
                  |> to_existing_atom(:asc)
                  |> to_atom_orders()} do
            q |> order_by([{^order_atom, ^field_atom}])
          end
        end)
    end
  end

  def paging_filter(query, conn) do
    page = parse_int(conn.params["page"], 1)
    page_size = parse_int(conn.params["page_size"], 10)
    offset = page_size * (page - 1)

    query
    |> limit([_], ^page_size)
    |> offset([_], ^offset)
  end

  defp parse_int(nil, default), do: default
  defp parse_int(x, default) when is_binary(x), do: fetch_int(Integer.parse(x), default)

  defp fetch_int({number, ""}, _default) when is_integer(number), do: number
  defp fetch_int(:error, default), do: default

  defp to_existing_atom(string, default) do
    try do
      string |> String.to_existing_atom()
    rescue
      _ -> default
    end
  end

  defp to_atom_fields(atom) when atom in @accepted_fields, do: atom
  defp to_atom_fields(_string), do: :id
  defp to_atom_orders(atom) when atom in @accepted_orders, do: atom
  defp to_atom_orders(_string), do: :asc
end
