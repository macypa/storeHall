defmodule StoreHallWeb.UserView do
  use StoreHallWeb, :view

  def get_title(path_info) do
    case path_info do
      :index -> "Listing users"
      :new -> "Add new user"
      :edit -> "Edit user"
      :show -> "Show user"
      _ -> ""
    end
  end
end
