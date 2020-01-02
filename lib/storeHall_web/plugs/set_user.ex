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

      set_locale(user)

      conn
      |> assign(:logged_user, user)
      |> assign(:user_token, token)
    end
  end

  def set_locale(user) do
    case user do
      nil ->
        nil

      user ->
        if Map.has_key?(user.settings, "locale") do
          StoreHallWeb.Gettext |> Gettext.put_locale(user.settings["locale"])
        end
    end
  end
end
