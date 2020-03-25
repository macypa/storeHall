defmodule StoreHallWeb.PageTitle do
  require StoreHallWeb.Gettext

  @suffix Application.get_env(:storeHall, :about)[:title]
  @suffix_description StoreHallWeb.Gettext.gettext(" is a site for free product listings")

  def page_title(assigns), do: assigns |> get

  def page_title_with_suffix(assigns),
    do: page_title(assigns) |> slice |> put_suffix

  def page_description(assigns),
    do: page_title(assigns) |> slice |> put_suffix |> put_description_suffix

  defp slice(title) do
    case String.length(to_string(title)) > 33 do
      true -> "#{String.slice(to_string(title), 0..33)}..."
      false -> title
    end
  end

  defp put_description_suffix(nil), do: @suffix_description
  defp put_description_suffix(title), do: "#{title} #{@suffix_description}"

  defp put_suffix(nil), do: @suffix
  defp put_suffix(title), do: "#{title} - #{@suffix}"

  defp get(%{view_module: StoreHallWeb.ErrorView, view_template: "404.html"}),
    do: StoreHallWeb.Gettext.gettext("Not Found")

  defp get(%{view_module: StoreHallWeb.ErrorView, view_template: "500.html"}),
    do: StoreHallWeb.Gettext.gettext("Internal Server Error")

  defp get(%{view_module: StoreHallWeb.AboutView, view_template: "contacts.html"}),
    do: StoreHallWeb.Gettext.gettext("Contacts")

  defp get(%{view_module: StoreHallWeb.AboutView, view_template: "cookies.html"}),
    do: StoreHallWeb.Gettext.gettext("Cookies")

  defp get(%{view_module: StoreHallWeb.AboutView, view_template: "privacy.html"}),
    do: StoreHallWeb.Gettext.gettext("Privacy Title")

  defp get(%{view_module: StoreHallWeb.AboutView, view_template: "terms.html"}),
    do: StoreHallWeb.Gettext.gettext("Terms Title")

  defp get(%{view_module: StoreHallWeb.AboutView, view_template: "sponsor.html"}),
    do: StoreHallWeb.Gettext.gettext("Sponsor")

  defp get(%{view_module: StoreHallWeb.AboutView, view_template: "howto.html"}),
    do: StoreHallWeb.Gettext.gettext("How to")

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
