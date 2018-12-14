defmodule StoreHallWeb.Plugs.RequireAuth do
  import Plug.Conn
  import Phoenix.Controller

  alias StoreHallWeb.Router.Helpers

  def init(_params) do
  end

  def call(conn, _params) do
    if conn.assigns[:logged_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in.")
      |> redirect(to: Helpers.item_path(conn, :index))
      |> halt()
    end
  end
end
