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

  defp filter(:mail_credits_ask, dynamic, %{"min" => min_price, "max" => max_price}) do
    dynamic
    |> filter_min_max(:gte, "mail_credits_ask", min_price)
    |> filter_min_max(:lte, "mail_credits_ask", max_price)
  end

  defp filter(:mail_credits_ask, dynamic, %{"min" => min_price}) do
    dynamic
    |> filter_min_max(:gte, "mail_credits_ask", min_price)
  end

  defp filter(:mail_credits_ask, dynamic, %{"max" => max_price}) do
    dynamic
    |> filter_min_max(:lte, "mail_credits_ask", max_price)
  end

  defp filter(:mail_credits_ask, dynamic, _), do: dynamic
end
