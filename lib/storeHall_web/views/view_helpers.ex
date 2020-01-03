defmodule StoreHallWeb.ViewHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  use Phoenix.HTML
  alias StoreHallWeb.AuthController

  def get_logged_user_id(conn) do
    AuthController.get_logged_user_id(conn)
  end

  def is_logged_user?(conn, user_id) do
    logged_user_id = get_logged_user_id(conn)

    logged_user_id != nil and logged_user_id == user_id
  end

  def get_logged_user_image(conn) do
    AuthController.get_logged_user_image(conn)
  end
end
