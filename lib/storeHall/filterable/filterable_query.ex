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

  defp apply_command(op, fragment_commands = %{field: field}) when is_binary(field) do
    field = field |> String.split(",") |> Enum.map(fn s -> String.trim(s, " ") end)

    apply_command(op, %{fragment_commands | field: field})
  end

  defp apply_command(:and, fragment_commands) do
    construct_where_fragment(true, fragment_commands)
  end

  # {"or": [{
  #   "gte":{
  #     "field":"rating,score",
  #     "value":2
  #     }
  #   },{
  #   "gte":{
  #     "field":"price",
  #     "value":2
  #     }
  #   }
  #  ]
  # }
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
    dynamic(
      [c],
      fragment(
        "( (?.details#>>?) ~ '^-\\?([0-9]+[.]\\?[0-9]*|[.][0-9]+)$' and (?.details#>>?)::decimal < ? )",
        c,
        ^fields,
        c,
        ^fields,
        ^as_decimal(value)
      )
    )
  end

  defp apply_command(:lte, %{field: fields, value: value}) do
    dynamic(
      [c],
      fragment(
        "( (?.details#>>?) ~ '^-\\?([0-9]+[.]\\?[0-9]*|[.][0-9]+)$' and (?.details#>>?)::decimal <= ? )",
        c,
        ^fields,
        c,
        ^fields,
        ^as_decimal(value)
      )
    )
  end

  defp apply_command(:gt, %{field: fields, value: value}) do
    dynamic(
      [c],
      fragment(
        "( (?.details#>>?) ~ '^-\\?([0-9]+[.]\\?[0-9]*|[.][0-9]+)$' and (?.details#>>?)::decimal > ? )",
        c,
        ^fields,
        c,
        ^fields,
        ^as_decimal(value)
      )
    )
  end

  # {"gte": {"field": "rating, core", "value": 4}}
  defp apply_command(:gte, %{field: fields, value: value}) do
    dynamic(
      [c],
      fragment(
        "( (?.details#>>?) ~ '^-\\?([0-9]+[.]\\?[0-9]*|[.][0-9]+)$' and (?.details#>>?)::decimal >= ? )",
        c,
        ^fields,
        c,
        ^fields,
        ^as_decimal(value)
      )
    )
  end

  defp apply_command(:in, %{field: fields, value: value}) do
    dynamic(
      [c],
      fragment(
        "(?.details#>?) \\?| ?",
        c,
        ^fields,
        ^value
      )
    )
  end

  # {"eq": {"field": "price", "value": "20.4"}}
  defp apply_command(:eq, %{field: fields, value: value}) do
    dynamic(
      [c],
      fragment(
        "(?.details#>>?)::varchar = ? ",
        c,
        ^fields,
        ^to_string(value)
      )
    )
  end

  defp apply_command(:has, %{field: fields, value: value}) do
    dynamic(
      [c],
      fragment(
        "(?.details#>>?) LIKE '%' || ? || '%' ",
        c,
        ^fields,
        ^to_string(value)
      )
    )
  end

  # {
  #      "has":{
  #        "value":"price"
  #        }
  #    }
  defp apply_command(:has, %{field: fields}) do
    dynamic(
      [c],
      fragment(
        "(?.details#>>?) is not null ",
        c,
        ^fields
      )
    )
  end

  # needs to preload user in ItemFilter.search_filter
  #
  # |> join(:left, [c], u in assoc(c, :author))
  # |> preload([:author])
  #
  # defp apply_command(:min_author_rating_filter, %{field: fields, value: value}) do
  #   fragment(
  #     " (user_details->'rating'->>'score')::decimal >= ? ",
  #     ^as_decimal(value)
  #   )
  #   |> dynamic
  # end

  defp apply_command(:length_at_least, %{field: fields, value: value}) do
    dynamic(
      [c],
      fragment(
        "jsonb_array_length(?.details#>?) >= ?",
        c,
        ^fields,
        ^as_decimal(value)
      )
    )
  end

  defp as_decimal(value) do
    try do
      value |> to_string() |> Integer.parse() |> elem(0)
    rescue
      _ -> 0
    end
  end
end
