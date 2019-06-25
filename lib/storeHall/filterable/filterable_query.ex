defmodule StoreHall.FilterableQuery do
  import Ecto.Query, warn: false

  import StoreHall.DefaultFilter
  # Example
  # {
  #  {lte: {field: "year", value: "1999"}},
  #  {or: [
  #    {contains: {field: "Bluetooth", value: "BT4"}},
  #    {or: [
  #      {contains: {field: "Bluetooth", value: "BT4"}},
  #      {in: {field: "extras", value:["GPS", "bluetooth"]}}
  #    ]},
  #    {in: {field: "extras", value:["GPS", "bluetooth"]}}
  #  ]}
  # }

  def filter(query, params) do
    query
    |> where(^construct_where_fragment(true, params))
  end

  def construct_where_fragment(dynamic, fragment_commands) do
    fragment_commands
    |> Enum.reduce(dynamic, fn {key, value}, acc ->
      clean_dynamic(:and, acc, apply_command(key, value))
    end)
  end

  defp apply_command(:and, fragment_commands) do
    construct_where_fragment(true, fragment_commands)
  end

  # @accepted_fields [:id, :inserted_at, :updated_at, :name]
  defp apply_command(:or, fragment_commands) do
    fragment_commands
    |> Enum.reduce(false, fn {key, value}, acc ->
      clean_dynamic(:or, acc, apply_command(key, value))
    end)
  end

  defp apply_command(:lte, %{field: fields, value: value}) do
    fragment_command(
      "(details",
      fields,
      ")::float <= ? ",
      value
    )
  end

  defp apply_command(:gte, %{field: fields, value: value}) do
    fragment_command(
      "(details",
      fields,
      ")::float >= ? ",
      value
    )
  end

  defp apply_command(:have_one, %{field: fields, value: value}) do
    fragment_command(
      "(details",
      fields,
      ") \\?| ?",
      value
    )
  end

  defp apply_command(:length_at_least, %{field: fields, value: value}) do
    fragment_command(
      "jsonb_array_length(details",
      fields,
      ") >= ?",
      value |> to_string() |> Integer.parse() |> elem(0)
    )
  end
end
