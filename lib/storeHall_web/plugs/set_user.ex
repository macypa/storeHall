defmodule StoreHall.Plugs.SetUser do
  import Plug.Conn
  alias StoreHallWeb.AuthController

  def init(_params) do
  end

  def call(conn, _params) do
    case AuthController.get_logged_user_id(conn) do
      nil ->
        conn
        |> assign(:user_token, "guest")

      user_id ->
        token = Phoenix.Token.sign(conn, "user token", user_id)

        set_locale(get_session(conn, :logged_user_settings), conn.params)

        conn
        # |> assign(:logged_user_id, user_id)
        |> assign(:user_token, token)
        |> StoreHallWeb.CookieConsentController.set_cookie_consent(user_id)
    end
  end

  def set_locale(user_settings), do: set_locale(user_settings, nil)

  def set_locale(_user_settings, params = %{"locale" => _lang}) do
    set_locale(params, nil)
  end

  def set_locale(nil, _params), do: nil

  def set_locale(user_settings, _params) do
    if Map.has_key?(user_settings, "locale") do
      StoreHallWeb.Gettext |> Gettext.put_locale(user_settings["locale"])
    end
  end
end
