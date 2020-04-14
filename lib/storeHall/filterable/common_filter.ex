defmodule StoreHall.CommonFilter do
  defmacro __using__(_opts) do
    quote do
      import Ecto.Query, warn: false
      alias StoreHall.FilterableQuery

      def search_filter(query, nil), do: query

      def search_filter(query, %{"filter" => search_terms}) do
        dynamic =
          search_terms
          |> Map.keys()
          |> Enum.reduce(true, fn search_key, acc ->
            try do
              filter(String.to_existing_atom(search_key), acc, Map.get(search_terms, search_key))
            rescue
              _ -> acc
            end
          end)

        query
        |> where(^dynamic)
      end

      def search_filter(query, _), do: query

      defp filter_min_max(dynamic, min_max, model_field, field_name, value, default_value) do
        case Integer.parse(value) do
          {^default_value, _} ->
            dynamic

          {value, _} when is_integer(value) ->
            FilterableQuery.construct_where_fragment(
              dynamic,
              %{
                min_max => %{
                  model_field: model_field,
                  field: [field_name],
                  value: value
                }
              }
            )

          _ ->
            dynamic
        end
      end

      defp filter_q(nil, dynamic), do: dynamic
      defp filter_q("", dynamic), do: dynamic

      defp filter_q(list, dynamic) when is_list(list) do
        list
        |> Enum.reduce(dynamic, fn search, acc ->
          filter_q(search, acc)
        end)
      end

      defp filter(:q, dynamic, list) when is_list(list) do
        list
        |> filter_q(dynamic)
      end

      defp filter(:q, dynamic, string) when is_binary(string) do
        string
        |> String.split(" ", trim: true)
        |> filter_q(dynamic)
      end

      defp filter(:q, dynamic, _), do: dynamic

      defp filter(:rating, dynamic, %{"min" => min_rating, "max" => max_rating}) do
        dynamic
        |> filter_min_max(:gte, :details, ["rating", "score"], min_rating, -1)
        |> filter_min_max(:lte, :details, ["rating", "score"], max_rating, 500)
      end

      defp filter(:rating, dynamic, %{"min" => min_rating}) do
        dynamic
        |> filter_min_max(:gte, :details, ["rating", "score"], min_rating, -1)
      end

      defp filter(:rating, dynamic, %{"max" => max_rating}) do
        dynamic
        |> filter_min_max(:lte, :details, ["rating", "score"], max_rating, 500)
      end

      defp filter(:rating, dynamic, _), do: dynamic

      # example value: {"gte": {"field": "rating, core", "value": 4}}
      # example url params mimicin with_image filter &filter[length_at_least][field][]=images&filter[length_at_least][value]=1
      defp filter(:"custom-filters", dynamic, value) do
        try do
          FilterableQuery.construct_where_fragment(
            dynamic,
            keys_to_existing_atom(value |> Jason.decode() |> elem(1))
          )
        rescue
          _ -> dynamic
        end
      end

      defp filter_range(field_atom, dynamic, model_field, %{
             "min" => min_price,
             "max" => max_price
           }) do
        dynamic
        |> filter_min_max(:gte, model_field, Atom.to_string(field_atom), min_price, 0)
        |> filter_min_max(:lte, model_field, Atom.to_string(field_atom), max_price, 0)
      end

      defp filter_range(field_atom, dynamic, model_field, %{"min" => min_price}) do
        dynamic
        |> filter_min_max(:gte, model_field, Atom.to_string(field_atom), min_price, 0)
      end

      defp filter_range(field_atom, dynamic, model_field, %{"max" => max_price}) do
        dynamic
        |> filter_min_max(:lte, model_field, Atom.to_string(field_atom), max_price, 0)
      end

      defp filter_range(field_atom, dynamic, _, _), do: dynamic

      defp filter_select_options(_, dynamic, _, value) when value == "", do: dynamic

      defp filter_select_options(field_atom, dynamic, model_field, value) do
        FilterableQuery.clean_dynamic(
          :and,
          dynamic,
          value
          |> String.split(",", trim: true)
          |> Enum.reduce(false, fn option, dyn ->
            FilterableQuery.clean_dynamic(
              :or,
              dyn,
              dynamic(
                [u],
                fragment(
                  "(?->>?)::varchar = ? ",
                  field(u, ^model_field),
                  ^Atom.to_string(field_atom),
                  ^to_string(option)
                )
              )
            )
          end)
        )
      end

      defp filter_select_multi_options(_, dynamic, _, value) when value == "", do: dynamic

      defp filter_select_multi_options(field_atom, dynamic, model_field, value) do
        FilterableQuery.construct_where_fragment(
          dynamic,
          %{
            in: %{
              model_field: model_field,
              field: [Atom.to_string(field_atom)],
              value:
                value
                |> String.split(",", trim: true)
            }
          }
        )
      end

      defp keys_to_existing_atom(value) when is_map(value) do
        for {key, val} <- value,
            into: %{},
            do: {String.to_existing_atom(key), keys_to_existing_atom(val)}
      end

      defp keys_to_existing_atom(value) when is_list(value) do
        value |> Enum.map(fn map -> keys_to_existing_atom(map) end)
      end

      defp keys_to_existing_atom(value), do: value
    end
  end
end
