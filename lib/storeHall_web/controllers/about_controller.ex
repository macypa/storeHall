defmodule StoreHallWeb.AboutController do
  use StoreHallWeb, :controller

  alias StoreHallWeb.AuthController
  alias StoreHall.Users
  alias StoreHall.Ratings
  alias StoreHall.Comments

  def index(conn, params) do
    user =
      Users.get_user!(Application.get_env(:storeHall, :about)[:user_id])
      |> Comments.preload_for(AuthController.get_user_id_from_conn(conn), params)
      |> Ratings.preload_for(AuthController.get_user_id_from_conn(conn), params)

    render(conn, "index.html", user: user)
  end

  def terms(conn, _) do
    render(conn, "terms.html")
  end

  def privacy(conn, _) do
    render(conn, "privacy.html")
  end

  def cookies(conn, _) do
    render(conn, "cookies.html")
  end
end
