defmodule StoreHallWeb.SessionController do
  use StoreHallWeb, :controller
  alias StoreHall.Users
  alias StoreHallWeb.AuthController

  def put_session(conn, %{"key" => key, "value" => value}) do
    split_key = key |> String.split(":", trim: true)
    key_atom = split_key |> hd |> String.to_existing_atom()
    inner_key_atom = split_key |> Enum.reverse() |> hd

    conn
    |> put_session(key_atom, %{inner_key_atom => value})
    |> send_resp(:ok, "")
  end

  def put_session(conn, %{"update" => _}) do
    case get_session(conn, :cu_id) do
      nil ->
        conn

      user_id ->
        conn
        |> AuthController.put_user_props_in_session(Users.get_user_with_settings!(user_id))
    end
    |> send_resp(:ok, "")
  end
end

# cookie = ""
# [_, payload, _] = String.split(cookie, ".", parts: 3)
# {:ok, encoded_term } = Base.url_decode64(payload, padding: false)
# :erlang.binary_to_term(encoded_term)
