defmodule StoreHallWeb.AboutController do
  use StoreHallWeb, :controller

  def index(conn, _) do
    render(conn, "index.html")
  end

  def contacts(conn, _) do
    render(conn, "contacts.html")
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
