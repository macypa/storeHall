defmodule StoreHall.UserFilter do
  use StoreHall.CommonFilter

  def with_marketing_consent(query) do
    query
    |> where([u], fragment("?->>? = ?", u.marketing_info, "marketing_consent", "agreed"))
  end

  def except_user_id(query, nil), do: query

  def except_user_id(query, logged_user_id) do
    query
    |> where([u], u.id != ^logged_user_id)
  end

  defp filter_q(search_string, dynamic) when is_binary(search_string) do
    search_string = "%#{search_string}%"

    FilterableQuery.clean_dynamic(
      :and,
      dynamic,
      dynamic(
        [u],
        ilike(u.name, ^search_string) or
          fragment("?->>? ILIKE ?", u.info, "description", ^search_string) or
          fragment("?->>? ILIKE ?", u.info, "address", ^search_string) or
          fragment("?->>? ILIKE ?", u.info, "contacts", ^search_string) or
          fragment("?->>? ILIKE ?", u.info, "mail", ^search_string) or
          fragment("?->>? ILIKE ?", u.info, "open", ^search_string)
      )
    )
  end

  defp filter(:mail_credits_ask, dynamic, params),
    do: filter_range(:mail_credits_ask, dynamic, :marketing_info, params)

  defp filter(:work_experience, dynamic, params),
    do: filter_range(:work_experience, dynamic, :marketing_info, params)

  defp filter(:age, dynamic, params),
    do: filter_range(:age, dynamic, :marketing_info, params)

  defp filter(:height, dynamic, params),
    do: filter_range(:height, dynamic, :marketing_info, params)

  defp filter(:weight, dynamic, params),
    do: filter_range(:weight, dynamic, :marketing_info, params)

  defp filter(:kids, dynamic, params), do: filter_range(:kids, dynamic, :marketing_info, params)

  defp filter(:merchant_type, dynamic, value),
    do: filter_select_options(:merchant_type, dynamic, :details, value)

  defp filter(:marital_status, dynamic, value),
    do: filter_select_options(:marital_status, dynamic, :marketing_info, value)

  defp filter(:gender, dynamic, value),
    do: filter_select_options(:gender, dynamic, :marketing_info, value)

  defp filter(:cities, dynamic, value),
    do: filter_select_multi_options(:cities, dynamic, :marketing_info, value)

  defp filter(:kids_age, dynamic, value),
    do: filter_select_multi_options(:kids_age, dynamic, :marketing_info, value)

  defp filter(:interests, dynamic, value),
    do: filter_select_multi_options(:interests, dynamic, :marketing_info, value)

  defp filter(:job_sector, dynamic, value),
    do: filter_select_multi_options(:job_sector, dynamic, :marketing_info, value)
end
