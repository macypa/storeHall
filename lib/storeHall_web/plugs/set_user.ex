defmodule StoreHall.Plugs.SetUser do
  import Plug.Conn

  alias StoreHall.Repo
  alias StoreHall.Users
  alias StoreHall.Users.User

  def init(_params) do
  end

  def call(conn, _params) do
    if conn.assigns[:user] do
      conn
    else
      assign(conn, :user, get_session(conn, :user))
    end
  end
end
