defmodule StoreHallWeb.ItemView do
  use StoreHallWeb, :view

  def get_title(path_info) do
    case path_info do
      :index -> "Listing Items"
      :new -> "Add new item"
      :edit -> "Edit item"
      :show -> "Show item"
      _ -> ""
    end
  end
end
