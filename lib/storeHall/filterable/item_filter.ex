defmodule StoreHall.ItemFilter do
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

  defp filter_q(nil, dynamic), do: dynamic
  defp filter_q("", dynamic), do: dynamic

  defp filter_q(search_string, dynamic) when is_binary(search_string) and search_string == "",
    do: dynamic

  defp filter_q(search_string, dynamic) when is_binary(search_string) do
    search_string = "%#{search_string}%"

    FilterableQuery.clean_dynamic(
      :and,
      dynamic,
      dynamic(
        [u],
        ilike(u.name, ^search_string) or
          ilike(u.user_id, ^search_string) or
          fragment("?->>? ILIKE ?", u.details, "tags", ^search_string) or
          fragment("?->>? ILIKE ?", u.details, "cities", ^search_string) or
          fragment("?->>? ILIKE ?", u.details, "description", ^search_string) or
          fragment("?->>? ILIKE ?", u.details, "conditions", ^search_string) or
          fragment("?->>? ILIKE ?", u.details, "features", ^search_string)
      )
    )
  end

  defp filter_q(list, dynamic) when is_list(list) do
    list
    |> Enum.reduce(dynamic, fn search, acc ->
      filter_q(search, acc)
    end)
  end

  defp filter_min_max(dynamic, min_max, field_name, value, default_value \\ 0) do
    case Integer.parse(value) do
      {^default_value, _} ->
        dynamic

      {value, _} when is_integer(value) ->
        FilterableQuery.construct_where_fragment(
          dynamic,
          %{
            min_max => %{
              field: [field_name],
              value: value
            }
          }
        )

      _ ->
        dynamic
    end
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

  defp filter(:price, dynamic, %{"min" => min_price, "max" => max_price}) do
    dynamic
    |> filter_min_max(:gte, "price", min_price)
    |> filter_min_max(:lte, "price", max_price)
  end

  defp filter(:price, dynamic, %{"min" => min_price}) do
    dynamic
    |> filter_min_max(:gte, "price", min_price)
  end

  defp filter(:price, dynamic, %{"max" => max_price}) do
    dynamic
    |> filter_min_max(:lte, "price", max_price)
  end

  defp filter(:price, dynamic, _), do: dynamic

  defp filter(:discount, dynamic, %{"min" => min_discount, "max" => max_discount}) do
    dynamic
    |> filter_min_max(:gte, "discount", min_discount)
    |> filter_min_max(:lte, "discount", max_discount)
  end

  defp filter(:discount, dynamic, %{"min" => min_discount}) do
    dynamic
    |> filter_min_max(:gte, "discount", min_discount)
  end

  defp filter(:discount, dynamic, %{"max" => max_discount}) do
    dynamic
    |> filter_min_max(:lte, "discount", max_discount)
  end

  defp filter(:discount, dynamic, _), do: dynamic

  defp filter(:rating, dynamic, %{"min" => min_rating, "max" => max_rating}) do
    dynamic
    |> filter_min_max(:gte, ["rating", "score"], min_rating, -1)
    |> filter_min_max(:lte, ["rating", "score"], max_rating, 500)
  end

  defp filter(:rating, dynamic, %{"min" => min_rating}) do
    dynamic
    |> filter_min_max(:gte, ["rating", "score"], min_rating, -1)
  end

  defp filter(:rating, dynamic, %{"max" => max_rating}) do
    dynamic
    |> filter_min_max(:lte, ["rating", "score"], max_rating, 500)
  end

  defp filter(:rating, dynamic, _), do: dynamic

  defp filter(:tags, dynamic, value) when value == "", do: dynamic

  defp filter(:tags, dynamic, value) do
    FilterableQuery.clean_dynamic(
      :and,
      dynamic,
      value
      |> String.split(",", trim: true)
      |> Enum.reduce(false, fn tag, dyn ->
        FilterableQuery.construct_where_fragment(
          :or,
          dyn,
          %{
            has: %{
              field: ["tags"],
              value: tag
            }
          }
        )
      end)
    )
  end

  defp filter(:cities, dynamic, value) when value == "", do: dynamic

  defp filter(:cities, dynamic, value) do
    FilterableQuery.construct_where_fragment(
      dynamic,
      %{
        in: %{
          field: ["cities"],
          value:
            value
            |> String.split(",", trim: true)
        }
      }
    )
  end

  defp filter(:merchant_type, dynamic, value) when value == "", do: dynamic

  defp filter(:merchant_type, dynamic, value) do
    FilterableQuery.clean_dynamic(
      :and,
      dynamic,
      value
      |> String.split(",", trim: true)
      |> Enum.reduce(dynamic, fn merch_type, dyn ->
        FilterableQuery.clean_dynamic(
          :or,
          dyn,
          dynamic(
            [c, a: u],
            fragment(
              "(?.details->>?)::varchar = ? ",
              u,
              "merchant_type",
              ^to_string(merch_type)
            )
          )
        )
      end)
    )
  end

  defp filter(:merchant, dynamic, value) when value == "", do: dynamic

  defp filter(:merchant, dynamic, value) do
    value
    |> String.split(",", trim: true)
    |> Enum.reduce(dynamic, fn merch, dyn ->
      FilterableQuery.clean_dynamic(:or, dyn, dynamic([u], u.user_id == ^merch))
    end)
  end

  defp filter(:"with-image", dynamic, _value) do
    FilterableQuery.construct_where_fragment(
      dynamic,
      %{
        length_at_least: %{
          field: ["images"],
          value: 1
        }
      }
    )
  end

  # example ?filter[features]=[{"harakteristika"%3A"rrr"}%2C{"friendly"%3A"www"}]
  defp filter(:features, dynamic, value) do
    FilterableQuery.clean_dynamic(
      :and,
      dynamic,
      try do
        value
        |> Jason.decode!()
        |> Enum.reduce(dynamic, fn feat, dyn ->
          split_feat = String.split(feat, ":", trim: true)

          key = split_feat |> hd
          value = feat |> String.replace_prefix(key <> ":", "")

          FilterableQuery.construct_where_fragment(
            :or,
            dyn,
            %{
              has: %{
                field: ["features"],
                value: "#{key}:%#{value}%"
              }
            }
          )
        end)
      rescue
        _ -> dynamic
      end
    )
  end

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

  defp filter(_, dynamic, _), do: dynamic

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
