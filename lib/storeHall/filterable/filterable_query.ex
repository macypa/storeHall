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

  def construct_where_fragment(and_or \\ :and, dynamic, fragment_commands)

  def construct_where_fragment(:or, dynamic, fragment_commands) do
    fragment_commands
    |> Enum.reduce(dynamic, fn {key, value}, acc ->
      clean_dynamic(:or, acc, apply_command(key, value))
    end)
  end

  def construct_where_fragment(_, dynamic, fragment_commands) do
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
    field = field |> String.split(",", trim: true) |> Enum.map(fn s -> String.trim(s, " ") end)

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

  defp apply_command(:lt, command_data = %{field: fields, value: value}) do
    dynamic(
      [c],
      fragment(
        "( (?#>>?) ~ '^-\\?([0-9]+[.]\\?[0-9]*|[.][0-9]+)$' and (?#>>?)::decimal < ? )",
        field(c, ^get_model_field(command_data)),
        ^fields,
        field(c, ^get_model_field(command_data)),
        ^fields,
        ^as_decimal(value)
      )
    )
  end

  defp apply_command(:lte, command_data = %{field: fields, value: value}) do
    dynamic(
      [c],
      fragment(
        "( (?#>>?) ~ '^-\\?([0-9]+[.]\\?[0-9]*|[.][0-9]+)$' and (?#>>?)::decimal <= ? )",
        field(c, ^get_model_field(command_data)),
        ^fields,
        field(c, ^get_model_field(command_data)),
        ^fields,
        ^as_decimal(value)
      )
    )
  end

  defp apply_command(:gt, command_data = %{field: fields, value: value}) do
    dynamic(
      [c],
      fragment(
        "( (?#>>?) ~ '^-\\?([0-9]+[.]\\?[0-9]*|[.][0-9]+)$' and (?#>>?)::decimal > ? )",
        field(c, ^get_model_field(command_data)),
        ^fields,
        field(c, ^get_model_field(command_data)),
        ^fields,
        ^as_decimal(value)
      )
    )
  end

  # {"gte": {"field": "rating, core", "value": 4}}
  defp apply_command(:gte, command_data = %{field: fields, value: value}) do
    dynamic(
      [c],
      fragment(
        "( (?#>>?) ~ '^-\\?([0-9]+[.]\\?[0-9]*|[.][0-9]+)$' and (?#>>?)::decimal >= ? )",
        field(c, ^get_model_field(command_data)),
        ^fields,
        field(c, ^get_model_field(command_data)),
        ^fields,
        ^as_decimal(value)
      )
    )
  end

  defp apply_command(:in, command_data = %{field: fields, value: value}) do
    dynamic(
      [c],
      fragment(
        "(?#>?) \\?| ?",
        field(c, ^get_model_field(command_data)),
        ^fields,
        ^value
      )
    )
  end

  # {"eq": {"field": "price", "value": "20.4"}}
  defp apply_command(:eq, command_data = %{field: fields, value: value}) do
    dynamic(
      [c],
      fragment(
        "(?#>>?)::varchar = ? ",
        field(c, ^get_model_field(command_data)),
        ^fields,
        ^to_string(value)
      )
    )
  end

  defp apply_command(:has, command_data = %{field: fields, value: value}) do
    dynamic(
      [c],
      fragment(
        "(?#>>?) LIKE '%' || ? || '%' ",
        field(c, ^get_model_field(command_data)),
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
  defp apply_command(:has, command_data = %{field: fields}) do
    dynamic(
      [c],
      fragment(
        "(?#>>?) is not null ",
        field(c, ^get_model_field(command_data)),
        ^fields
      )
    )
  end

  # needs to preload user in ItemFilter.search_filter
  #
  # |> join(:left, [c], u in assoc(c, :author))
  # |> preload([:author])
  #
  # defp apply_command(:min_author_rating_filter, command_data = %{field: fields, value: value}) do
  #   fragment(
  #     " (user_details->'rating'->>'score')::decimal >= ? ",
  #     ^as_decimal(value)
  #   )
  #   |> dynamic
  # end

  defp apply_command(:length_at_least, command_data = %{field: fields, value: value}) do
    dynamic(
      [c],
      fragment(
        "jsonb_array_length(?#>?) >= ?",
        field(c, ^get_model_field(command_data)),
        ^fields,
        ^as_decimal(value)
      )
    )
  end

  defp get_model_field(%{model_field: model_field}), do: model_field
  defp get_model_field(_), do: :details

  defp as_decimal(value) do
    try do
      value |> to_string() |> Integer.parse() |> elem(0)
    rescue
      _ -> 0
    end
  end
end
