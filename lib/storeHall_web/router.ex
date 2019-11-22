defmodule StoreHallWeb.Router do
  use StoreHallWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug StoreHall.Plugs.SetUser
    plug NavigationHistory.Tracker
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug StoreHallWeb.Plugs.RequireAuth
  end

  scope "/", StoreHallWeb do
    pipe_through [:browser, :auth]

    resources "/users", UserController, only: [:edit, :update, :delete]
    resources "/items", ItemController, only: [:new, :create, :edit, :update, :delete]
  end

  scope "/", StoreHallWeb do
    pipe_through :browser

    get "/", Redirector, to: "/items"
    get "/accept_cookies", CookieConsent, default: "/items"

    resources "/users", UserController, only: [:index, :show]
    resources "/items", ItemController, only: [:index, :show]
  end

  scope "/auth", StoreHallWeb do
    pipe_through :browser

    get "/delete", AuthController, :delete
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :new
  end

  # Other scopes may use custom stacks.
  # scope "/api", StoreHallWeb do
  #   pipe_through :api
  # end
end

defmodule StoreHallWeb.Redirector do
  def init(opts), do: opts

  def call(conn, opts) do
    conn
    |> Phoenix.Controller.redirect(opts)
    |> Plug.Conn.halt()
  end
end

defmodule StoreHallWeb.CookieConsent do
  def init(opts), do: opts

  def call(conn, opts) do
    conn
    |> Plug.Conn.put_session(:cookie_consent_agreed, "cookie_consent_agreed")
    |> Phoenix.Controller.redirect(to: NavigationHistory.last_path(conn, 1, opts))
  end
end
