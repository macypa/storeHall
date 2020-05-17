defmodule StoreHallWeb.PageTitle do
  require StoreHallWeb.Gettext
  import PhoenixHtmlSanitizer.Helpers
  import Phoenix.HTML

  @suffix Application.get_env(:storeHall, :about)[:title]
  @suffix_description StoreHallWeb.Gettext.gettext(" is a site for free product listings")

  defp description_suffix(), do: "#{@suffix}#{@suffix_description}"
  defp put_description_suffix(nil), do: description_suffix()
  defp put_description_suffix(""), do: description_suffix()
  defp put_description_suffix(title), do: "#{title} - #{description_suffix()}"

  defp put_suffix(nil), do: @suffix
  defp put_suffix(title), do: "#{title} - #{@suffix}"

  def page_title(assigns), do: assigns |> get
  def page_title_with_suffix(assigns), do: page_title(assigns) |> slice(33) |> put_suffix

  def page_description(assigns = %{view_module: StoreHallWeb.AboutView}),
    do: page_title(assigns) |> put_description_suffix

  def page_description(assigns = %{user: user}), do: page_description(assigns, user)

  def page_description(assigns = %{item: item}), do: page_description(assigns, item)

  def page_description(assigns), do: page_title(assigns) |> put_description_suffix

  def page_description(assigns, model) do
    case model.details["description"] |> slice(255) do
      "" -> page_title(assigns) |> put_description_suffix
      desc -> desc
    end
  end

  defp slice(nil, _len), do: nil
  defp slice({:safe, ""}, _len), do: nil
  defp slice({:safe, title}, len), do: slice(title, len)

  defp slice(title, len) do
    case String.length(to_string(title)) > len do
      true -> "#{String.slice(to_string(title), 0..len)}..."
      false -> title
    end
    |> sanitize(:strip_tags)
    |> html_escape()
    |> elem(1)
  end

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

  defp get(%{users: _users}), do: StoreHallWeb.Gettext.gettext("Add mail")
  defp get(%{mails: _mails}), do: StoreHallWeb.Gettext.gettext("Listing Mails")

  defp get(%{mail: mail}) do
    mail.details["title"]
  end

  defp get(%{item: item}) do
    item.name
  end

  defp get(_), do: nil

  def page_image(%{user: user}) do
    StoreHall.Images.cover_image(user) |> full_image_url
  end

  def page_image(%{item: item}) do
    case StoreHall.Images.cover_image(item) do
      nil -> StoreHall.Images.cover_image(item.user)
      image -> image
    end
    |> full_image_url
  end

  def page_image(_assigns) do
    nil
  end

  defp full_image_url(nil), do: nil

  defp full_image_url(img) do
    case String.starts_with?(img, "/uploads") do
      true ->
        domain = Application.get_env(:storeHall, :about)[:host]
        "#{domain}#{img}"

      false ->
        img
    end
  end
end
