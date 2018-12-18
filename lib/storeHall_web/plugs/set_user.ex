defmodule StoreHall.Plugs.SetUser do
  import Plug.Conn

  alias StoreHall.Repo
  alias StoreHall.Users
  alias StoreHall.Users.User

  def init(_params) do
  end

  def call(conn, _params) do
    if conn.assigns[:logged_user] do
      conn
    else
      user = get_session(conn, :logged_user)
      token = Phoenix.Token.sign(conn, "user token", user.id)

      conn
      |> assign(:logged_user, user)
      |> assign(:user_token, token)
    end
  end
end
