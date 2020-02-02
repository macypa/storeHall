defmodule StoreHallWeb.Sitemaps do
  alias StoreHallWeb.{Endpoint, Router.Helpers}
  alias StoreHall.Items

  @host "https://#{Application.get_env(:storeHall, Endpoint)[:url][:host]}"
  @filename "sitemap"
  @public_path "sitemaps/"
  @files_path "priv/static/sitemaps/"
  def filename(), do: @filename
  def path(), do: "#{@files_path}#{@filename}.xml.gz"
  def url(), do: "#{@host}/#{@filename}.xml.gz"

  use Sitemap,
    host: @host,
    filename: @filename,
    files_path: @files_path,
    public_path: "sitemaps/"

  def generate do
    create do
      File.rm(@files_path)

      add_url(Helpers.item_path(Endpoint, :index), priority: 1, changefreq: "weekly")
      add_url(Helpers.about_path(Endpoint, :index), priority: 0.7, changefreq: "weekly")
      add_url(Helpers.about_path(Endpoint, :terms), priority: 0.7, changefreq: "monthly")
      add_url(Helpers.about_path(Endpoint, :privacy), priority: 0.7, changefreq: "monthly")
      add_url(Helpers.about_path(Endpoint, :cookies), priority: 0.7, changefreq: "monthly")
      add_url(Helpers.about_path(Endpoint, :sponsor), priority: 0.7, changefreq: "weekly")

      for item <- Items.list_items_for_sitemap() do
        add_url(
          Helpers.user_item_path(Endpoint, :show, item.user_id, item.id),
          lastmod: item.updated_at,
          priority: 0.7,
          changefreq: "daily"
        )
      end

      for merchant <- Items.item_filters()["merchant"] do
        add_url(Helpers.user_path(Endpoint, :show, merchant |> elem(0)),
          priority: 0.6,
          changefreq: "daily"
        )
      end
    end

    # notify search engines (currently Google and Bing) of the updated sitemap
    ping()
  end

  def add_url(url, attrs \\ []) do
    alternates = {
      :alternates,
      [
        [
          href: "#{@host}#{url}?lang=en",
          lang: "en",
          nofollow: true,
          media: nil
        ],
        [
          href: "#{@host}#{url}",
          lang: "x-default",
          nofollow: true,
          media: nil
        ]
      ]
    }

    add(
      url,
      [alternates | attrs]
    )
  end
end
