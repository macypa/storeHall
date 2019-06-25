defmodule StoreHall.FilterableQuery do
  import Ecto.Query, warn: false

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

  def clean_dynamic(_, nil, dynamic), do: dynamic
  def clean_dynamic(_, false, dynamic), do: dynamic
  def clean_dynamic(_, true, dynamic), do: dynamic

  def clean_dynamic(:and, acc, dynamic) do
    dynamic(^acc and ^dynamic)
  end

  def clean_dynamic(:or, acc, dynamic) do
    dynamic(^acc or ^dynamic)
  end

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

  defp apply_command(_, %{field: nil}), do: true
  defp apply_command(_, %{field: []}), do: true
  defp apply_command(_, %{field: [""]}), do: true
  defp apply_command(_, %{value: ""}), do: true

  defp apply_command(op, %{field: field, value: value}) when is_binary(field) do
    field = field |> String.split(",") |> Enum.map(fn s -> String.trim(s, " ") end)

    apply_command(op, %{
      field: field,
      value: value
    })
  end

  defp apply_command(:and, fragment_commands) do
    construct_where_fragment(true, fragment_commands)
  end

  # @accepted_fields [:id, :inserted_at, :updated_at, :name]
  defp apply_command(:or, fragment_commands) do
    fragment_commands
    |> Enum.reduce(false, fn map, acc ->
      map
      |> Enum.reduce(acc, fn {key, value}, acc ->
        clean_dynamic(:or, acc, apply_command(key, value))
      end)
    end)
  end

  defp apply_command(:lt, %{field: fields, value: value}) do
    fragment(
      "(details#>?)::float < ? ",
      ^fields,
      ^as_float(value)
    )
    |> dynamic
  end

  defp apply_command(:lte, %{field: fields, value: value}) do
    fragment(
      "(details#>?)::float <= ? ",
      ^fields,
      ^as_float(value)
    )
    |> dynamic
  end

  defp apply_command(:gt, %{field: fields, value: value}) do
    fragment(
      "(details#>>?)::float > ? ",
      ^fields,
      ^as_float(value)
    )
    |> dynamic
  end

  defp apply_command(:gte, %{field: fields, value: value}) do
    fragment(
      "(details#>>?)::float >= ? ",
      ^fields,
      ^as_float(value)
    )
    |> dynamic
  end

  defp apply_command(:in, %{field: fields, value: value}) do
    fragment(
      "(details#>?) \\?| ?",
      ^fields,
      ^value
    )
    |> dynamic
  end

  defp apply_command(:length_at_least, %{field: fields, value: value}) do
    fragment(
      "jsonb_array_length(details#>?) >= ?",
      ^fields,
      ^as_float(value)
    )
    |> dynamic
  end

  defp as_float(value) do
    try do
      value |> to_string() |> Integer.parse() |> elem(0)
    rescue
      _ -> 0
    end
  end
end
