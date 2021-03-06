defmodule StoreHallWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :storeHall

  socket "/socket", StoreHallWeb.UserSocket,
    websocket: true,
    longpoll: false

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :storeHall,
    gzip: true,
    only:
      ~w(css fonts images js favicon.ico logo.svg sitemaps .well-known googlef8312b0ac14d6c82.html)

  plug Plug.Static, at: "/uploads", from: Path.expand('./uploads'), gzip: false

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session,
    store: :cookie,
    key: "_session_key",
    signing_salt: "8x6mVJBW",
    # 60*60*24*30
    max_age: 2_592_000

  plug StoreHallWeb.Router
end
