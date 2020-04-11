defmodule StoreHall.ItemFilter do
  use StoreHall.CommonFilter

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

  defp filter(:cities, dynamic, value), do: filter_select_multi_options(:cities, dynamic, value)

  defp filter(:price, dynamic, params), do: filter_range(:price, dynamic, params)
  defp filter(:discount, dynamic, params), do: filter_range(:discount, dynamic, params)

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

  defp filter(:merchant_type, dynamic, value) when value == "", do: dynamic

  defp filter(:merchant_type, dynamic, value) do
    FilterableQuery.clean_dynamic(
      :and,
      dynamic,
      value
      |> String.split(",", trim: true)
      |> Enum.reduce(false, fn merch_type, dyn ->
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
        |> Enum.reduce(false, fn feat, dyn ->
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

  defp filter(_, dynamic, _), do: dynamic
end
