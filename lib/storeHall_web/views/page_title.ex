defmodule StoreHallWeb.PageTitle do
  require StoreHallWeb.Gettext

  @suffix "Крали Марко"

  def page_title(assigns), do: assigns |> get
  def page_title_with_suffix(assigns), do: page_title(assigns) |> put_suffix

  defp put_suffix(nil), do: @suffix
  defp put_suffix(title), do: title <> " - " <> @suffix

  defp get(%{users: _user}), do: StoreHallWeb.Gettext.gettext("Listing users")

  defp get(%{user: user}) do
    user.first_name <> " " <> user.last_name
  end

  defp get(%{item: item}) do
    item.name
  end

  defp get(_), do: nil
end
