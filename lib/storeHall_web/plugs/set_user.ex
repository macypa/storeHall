defmodule StoreHall.Plugs.SetUser do
  import Plug.Conn

  def init(_params) do
  end

  def call(conn, _params) do
    if conn.assigns[:logged_user] do
      conn
    else
      user = get_session(conn, :logged_user)

      token =
        case user do
          nil -> "guest"
          user -> Phoenix.Token.sign(conn, "user token", user.id)
        end

      conn
      |> assign(:logged_user, user)
      |> assign(:user_token, token)
    end
  end
end
