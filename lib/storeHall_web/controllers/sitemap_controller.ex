defmodule StoreHallWeb.SitemapController do
  use StoreHallWeb, :controller
  alias Plug.Conn
  alias StoreHallWeb.Sitemaps

  def robots(conn, _params) do
    spawn(fn -> Sitemaps.generate() end)

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Sitemap: #{Sitemaps.url()}")
  end

  def sitemap(conn, _params) do
    conn
    |> Conn.put_resp_content_type("application/gzip")
    |> Conn.send_file(200, Sitemaps.path())
  end
end
