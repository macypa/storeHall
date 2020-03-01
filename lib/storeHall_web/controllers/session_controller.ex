defmodule StoreHallWeb.SessionController do
  use StoreHallWeb, :controller

  def put_session(conn, %{"key" => key, "value" => value}) do
    conn
    |> put_session(key, value)
    |> send_resp(:ok, "")
  end
end
