defmodule StoreHallWeb.CookieConsentController do
  import Plug.Conn
  alias StoreHall.Users

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :logged_user) do
      nil ->
        conn

      user ->
        {:ok, user} = Users.update_user(user, %{"settings" => %{"cookie_consent" => "agreed"}})
        conn |> Users.put_in_session(user)
    end
    |> agree_to_cookie_consent()
    |> send_resp(:ok, "")
  end

  def agree_to_cookie_consent(conn) do
    conn
    |> get_session(:cookie_consent_agreed)
    |> case do
      "cookie_consent_agreed" -> conn
      _ -> put_session(conn, :cookie_consent_agreed, "cookie_consent_agreed")
    end
  end

  def set_cookie_consent(conn, user) do
    case user do
      nil -> conn
      user -> set_cookie_consent_from_user_settings(conn, user)
    end
  end

  defp set_cookie_consent_from_user_settings(conn, user) do
    case user do
      nil ->
        conn

      user ->
        case user.settings["cookie_consent"] do
          "agreed" -> agree_to_cookie_consent(conn)
          _ -> Plug.Conn.delete_session(conn, :cookie_consent_agreed)
        end
    end
  end
end
