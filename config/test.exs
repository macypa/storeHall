use Mix.Config

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

# Configure Google OAuth
config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: "561597658888-jf8k47pmjvnuo362h8kjg2cb389khroa.apps.googleusercontent.com",
  client_secret: "LWT6NmLgy33tTXoIyRkrVG5b"
