defmodule StoreHall.Plugs.SetUser do
  import Plug.Conn

  alias StoreHall.Repo
  alias StoreHall.Users
  alias StoreHall.Users.User

  def init(_params) do
  end

  def call(conn, _params) do
    if conn.assigns[:logged_user] do
      conn
    else
      assign(conn, :logged_user, get_session(conn, :logged_user))
    end
  end
end
