defmodule StoreHallWeb.Router do
  use StoreHallWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :put_secure_browser_headers
    plug StoreHall.Plugs.SetUser
  end

  pipeline :csrf do
    plug :protect_from_forgery
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug StoreHallWeb.Plugs.RequireAuth
  end

  scope "/", StoreHallWeb do
    pipe_through [:browser, :csrf, :auth]

    resources "/users", UserController, only: [:edit, :update, :delete] do
      resources "/items", ItemController, only: [:new, :create, :edit, :update, :delete]
      resources "/mails", MailController, only: [:index, :show, :delete]
      resources "/payments", PaymentController, only: [:index, :delete, :show, :new, :create]

      get "/withdraw", PaymentController, :withdraw

      get "/payment/thanks", PaymentController, :thanks
      get "/payment/cancel", PaymentController, :cancel
    end
  end

  scope "/", StoreHallWeb do
    pipe_through [:browser, :csrf]

    get "/robots.txt", SitemapController, :robots
    get "/sitemap.xml.gz", SitemapController, :sitemap
    get "/accept_cookies", CookieConsentController, :agree
    get "/put_session", SessionController, :put_session

    resources "/", ItemController, only: [:index]

    resources "/users", UserController, only: [:index, :show] do
      resources "/items", ItemController, only: [:show]
    end
  end

  scope "/", StoreHallWeb do
    pipe_through [:browser]

    post "/payment/status", PaymentController, :status
  end

  scope "/about", StoreHallWeb do
    pipe_through [:browser, :csrf]

    get "/", AboutController, :index
    get "/terms", AboutController, :terms
    get "/privacy", AboutController, :privacy
    # get "/cookies", AboutController, :cookies
    # get "/sponsor", AboutController, :sponsor
    get "/howto", AboutController, :howto

    get "/*path", Redirector, to: "/about"
  end

  scope "/auth", StoreHallWeb do
    pipe_through [:browser, :csrf]

    get "/delete", AuthController, :delete
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :new
  end

  scope "/", StoreHallWeb do
    pipe_through [:browser, :csrf]

    get "/*path", Redirector, to: "/"
  end

  # Other scopes may use custom stacks.
  # scope "/api", StoreHallWeb do
  #   pipe_through :api
  # end
end

defmodule StoreHallWeb.Redirector do
  use Phoenix.Controller
  require StoreHallWeb.Gettext

  def init(opts), do: opts

  def call(conn, opts) do
    conn
    |> put_status(:moved_permanently)
    |> put_flash(:error, StoreHallWeb.Gettext.gettext("Page not found"))
    |> redirect(opts)
    |> Plug.Conn.halt()
  end
end
