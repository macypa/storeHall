defmodule StoreHallWeb.PageTitle do
  require StoreHallWeb.Gettext

  @suffix Application.get_env(:storeHall, :about)[:title]

  def page_title(assigns), do: assigns |> get

  def page_title_with_suffix(assigns),
    do: page_title(assigns) |> String.slice(0..29) |> put_suffix

  defp put_suffix(nil), do: @suffix
  defp put_suffix(title), do: "#{title} - #{@suffix}"

  defp get(%{view_module: StoreHallWeb.AboutView, view_template: "contacts.html"}),
    do: StoreHallWeb.Gettext.gettext("Contacts")

  defp get(%{view_module: StoreHallWeb.AboutView, view_template: "cookies.html"}),
    do: StoreHallWeb.Gettext.gettext("Cookies")

  defp get(%{view_module: StoreHallWeb.AboutView, view_template: "privacy.html"}),
    do: StoreHallWeb.Gettext.gettext("Privacy")

  defp get(%{view_module: StoreHallWeb.AboutView, view_template: "terms.html"}),
    do: StoreHallWeb.Gettext.gettext("Terms")

  defp get(%{view_module: StoreHallWeb.AboutView, view_template: "sponsor.html"}),
    do: StoreHallWeb.Gettext.gettext("Sponsor")

  defp get(%{view_module: StoreHallWeb.AboutView}), do: StoreHallWeb.Gettext.gettext("About Us")

  defp get(%{items: _items, conn: %{params: %{"page" => page}}}) do
    StoreHallWeb.Gettext.gettext(" Page ") <> page
  end

  defp get(%{users: _users, conn: %{params: %{"page" => page}}}) do
    StoreHallWeb.Gettext.gettext("Listing users") <>
      StoreHallWeb.Gettext.gettext(" Page ") <> page
  end

  defp get(%{users: _users}), do: StoreHallWeb.Gettext.gettext("Listing users")

  defp get(%{user: user}) do
    "#{user.name}"
  end

  defp get(%{item: item}) do
    item.name
  end

  defp get(_), do: nil
end
