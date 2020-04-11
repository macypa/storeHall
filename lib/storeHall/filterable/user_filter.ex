defmodule StoreHall.UserFilter do
  use StoreHall.CommonFilter

  def with_marketing_consent(query) do
    query
    |> where([u], fragment("?->>? = ?", u.details, "marketing_consent", "agreed"))
  end

  defp filter_q(search_string, dynamic) when is_binary(search_string) do
    search_string = "%#{search_string}%"

    FilterableQuery.clean_dynamic(
      :and,
      dynamic,
      dynamic(
        [u],
        ilike(u.name, ^search_string) or
          fragment("?->>? ILIKE ?", u.details, "tags", ^search_string) or
          fragment("?->>? ILIKE ?", u.details, "cities", ^search_string) or
          fragment("?->>? ILIKE ?", u.details, "description", ^search_string) or
          fragment("?->>? ILIKE ?", u.details, "conditions", ^search_string) or
          fragment("?->>? ILIKE ?", u.details, "features", ^search_string)
      )
    )
  end

  defp filter(:mail_credits_ask, dynamic, params),
    do: filter_range(:mail_credits_ask, dynamic, params)

  defp filter(:work_experience, dynamic, params),
    do: filter_range(:work_experience, dynamic, params)

  defp filter(:height, dynamic, params), do: filter_range(:height, dynamic, params)
  defp filter(:weight, dynamic, params), do: filter_range(:weight, dynamic, params)
  defp filter(:kids, dynamic, params), do: filter_range(:kids, dynamic, params)

  defp filter(:merchant_type, dynamic, value),
    do: filter_select_options(:merchant_type, dynamic, value)

  defp filter(:marital_status, dynamic, value),
    do: filter_select_options(:marital_status, dynamic, value)

  defp filter(:gender, dynamic, value), do: filter_select_options(:gender, dynamic, value)

  defp filter(:cities, dynamic, value), do: filter_select_multi_options(:cities, dynamic, value)

  defp filter(:kids_age, dynamic, value),
    do: filter_select_multi_options(:kids_age, dynamic, value)

  defp filter(:interests, dynamic, value),
    do: filter_select_multi_options(:interests, dynamic, value)

  defp filter(:job_sector, dynamic, value),
    do: filter_select_multi_options(:job_sector, dynamic, value)
end
