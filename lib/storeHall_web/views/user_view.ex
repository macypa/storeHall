defmodule StoreHallWeb.UserView do
  use StoreHallWeb, :view

  def get_title(path_info) do
    case path_info do
      :index -> StoreHallWeb.Gettext.gettext("Listing users")
      :new -> StoreHallWeb.Gettext.gettext("Add new user")
      :edit -> StoreHallWeb.Gettext.gettext("Edit user")
      :show -> StoreHallWeb.Gettext.gettext("Show user")
      _ -> ""
    end
  end
end
