use Mix.Config

config :gettext, :default_locale, "en"

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :storeHall, StoreHallWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :storeHall, StoreHall.Repo,
  username: "postgres",
  password: "postgres",
  database: "storehall_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

import_config "test.secret.exs"

# # Configure Google OAuth
# config :ueberauth, Ueberauth.Strategy.Google.OAuth,
#   client_id: "",
#   client_secret: ""
#
# # Configure Facebook OAuth
# config :ueberauth, Ueberauth.Strategy.Facebook.OAuth,
#   client_id: "",
#   client_secret: ""
