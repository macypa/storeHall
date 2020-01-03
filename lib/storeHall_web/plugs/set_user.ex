defmodule StoreHall.Plugs.SetUser do
  import Plug.Conn

  def init(_params) do
  end

  def call(conn, _params) do
    if conn.assigns[:logged_user_id] do
      conn
    else
      user_id = get_session(conn, :logged_user_id)

      token =
        case user_id do
          nil -> "guest"
          user_id -> Phoenix.Token.sign(conn, "user token", user_id)
        end

      set_locale(get_session(conn, :logged_user_settings))

      conn
      |> assign(:logged_user_id, user_id)
      |> assign(:user_token, token)
      |> StoreHallWeb.CookieConsentController.set_cookie_consent(user_id)
    end
  end

  def set_locale(user_settings) do
    case user_settings do
      nil ->
        nil

      user_settings ->
        if Map.has_key?(user_settings, "locale") do
          StoreHallWeb.Gettext |> Gettext.put_locale(user_settings["locale"])
        end
    end
  end
end
