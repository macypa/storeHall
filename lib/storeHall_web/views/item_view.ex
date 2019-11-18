defmodule StoreHallWeb.ItemView do
  use StoreHallWeb, :view

  def get_title(path_info) do
    case path_info do
      :index -> StoreHallWeb.Gettext.gettext("Listing items")
      :new -> StoreHallWeb.Gettext.gettext("Add new item")
      :edit -> StoreHallWeb.Gettext.gettext("Edit item")
      :show -> StoreHallWeb.Gettext.gettext("Show item")
      _ -> ""
    end
  end
end
