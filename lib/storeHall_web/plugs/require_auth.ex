defmodule StoreHallWeb.Plugs.RequireAuth do
  import Plug.Conn
  import Phoenix.Controller
  require StoreHallWeb.Gettext
  alias StoreHallWeb.Router.Helpers, as: Routes
  alias StoreHallWeb.AuthController

  def init(_params) do
  end

  def call(conn, _params) do
    case AuthController.get_logged_user_id(conn) do
      nil ->
        conn
        |> put_flash(:error, StoreHallWeb.Gettext.gettext("You must be logged in."))
        |> redirect(to: Routes.item_path(conn, :index))
        |> halt()

      _user_id ->
        conn
    end
  end
end
