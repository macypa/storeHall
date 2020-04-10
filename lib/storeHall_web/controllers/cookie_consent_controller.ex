defmodule StoreHallWeb.CookieConsentController do
  import Plug.Conn
  alias StoreHall.Users
  alias StoreHallWeb.AuthController

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :logged_user_id) do
      nil ->
        conn

      user_id ->
        update_cookie_consent_to_agreed(conn, user_id)
    end
    |> agree_to_cookie_consent()
    |> send_resp(:ok, "")
  end

  def update_cookie_consent_to_agreed(conn, user_id) do
    {:ok, user} =
      Users.update_user(Users.get_user_with_settings(user_id), %{
        "settings" => %{"cookie_consent" => "agreed"}
      })

    conn |> AuthController.put_user_props_in_session(user)
  end

  def agree_to_cookie_consent(conn) do
    conn
    |> get_session(:cookie_consent_agreed)
    |> case do
      "cookie_consent_agreed" -> conn
      _ -> put_session(conn, :cookie_consent_agreed, "cookie_consent_agreed")
    end
  end

  def set_cookie_consent(conn, user_id) do
    case user_id do
      nil ->
        conn

      _ ->
        set_cookie_consent_from_user_settings(
          conn,
          get_session(conn, :logged_user_settings)
        )
    end
  end

  defp set_cookie_consent_from_user_settings(conn, user_settings) do
    case user_settings do
      nil ->
        conn

      user_settings ->
        case user_settings["cookie_consent"] do
          "agreed" ->
            agree_to_cookie_consent(conn)

          _ ->
            conn |> configure_session(drop: true)
            # Plug.Conn.delete_session(conn, :cookie_consent_agreed)
        end
    end
  end
end
