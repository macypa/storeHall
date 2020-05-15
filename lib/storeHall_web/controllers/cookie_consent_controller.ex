defmodule StoreHallWeb.CookieConsentController do
  import Plug.Conn
  alias StoreHall.Users
  alias StoreHallWeb.AuthController

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :cu_id) do
      nil ->
        conn
        |> put_session(:cu_settings, %{"cookie_consent" => "agreed"})

      user_id ->
        conn
        |> update_cookie_consent_to_agreed(user_id)
    end
    |> send_resp(:ok, "")
  end

  def update_cookie_consent_to_agreed(conn, user_id) do
    {:ok, user} =
      Users.update_user(Users.get_user_with_settings(user_id), %{
        settings: %{"cookie_consent" => "agreed"}
      })

    conn |> AuthController.put_user_props_in_session(user)
  end
end
