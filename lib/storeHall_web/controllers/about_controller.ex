defmodule StoreHallWeb.AboutController do
  use StoreHallWeb, :controller

  alias StoreHallWeb.AuthController
  alias StoreHall.Users
  alias StoreHall.Ratings
  alias StoreHall.Comments
  alias StoreHall.Images

  def index(conn, params) do
    user =
      Users.get_user!(Application.get_env(:storeHall, :about)[:user_id], [:info])
      |> Images.append_images(:image)
      |> Comments.preload_for(AuthController.get_logged_user_id(conn), params)
      |> Ratings.preload_for(AuthController.get_logged_user_id(conn), params)

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

  def sponsor(conn, _) do
    render(conn, "sponsor.html")
  end

  def howto(conn, _) do
    render(conn, "howto.html")
  end
end
