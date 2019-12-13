defmodule StoreHallWeb.PageTitle do
  require StoreHallWeb.Gettext

  @suffix Application.get_env(:storeHall, :about)[:title]

  def page_title(assigns), do: assigns |> get
  def page_title_with_suffix(assigns), do: page_title(assigns) |> put_suffix

  defp put_suffix(nil), do: @suffix
  defp put_suffix(title), do: title <> " - " <> @suffix

  defp get(%{view_module: StoreHallWeb.AboutView, view_template: "contacts.html"}), do: StoreHallWeb.Gettext.gettext("Contacts")
  defp get(%{view_module: StoreHallWeb.AboutView, view_template: "cookies.html"}), do: StoreHallWeb.Gettext.gettext("Cookies")
  defp get(%{view_module: StoreHallWeb.AboutView, view_template: "privacy.html"}), do: StoreHallWeb.Gettext.gettext("Privacy")
  defp get(%{view_module: StoreHallWeb.AboutView, view_template: "terms.html"}), do: StoreHallWeb.Gettext.gettext("Terms")
  defp get(%{view_module: StoreHallWeb.AboutView}), do: StoreHallWeb.Gettext.gettext("About Us")

  defp get(%{users: _user}), do: StoreHallWeb.Gettext.gettext("Listing users")

  defp get(%{user: user}) do
    "#{user.first_name} #{user.last_name}"
  end

  defp get(%{item: item}) do
    item.name
  end

  defp get(_), do: nil
end
