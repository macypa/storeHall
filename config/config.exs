# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :storeHall,
  ecto_repos: [StoreHall.Repo]

# Configures the endpoint
config :storeHall, StoreHallWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "NpNI3dqJLXnYrzqdluT4KxYQqVhIPCwz2jsF4H5sYhvZn8EOl9i/PUsocP7GS7IS",
  render_errors: [view: StoreHallWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: StoreHall.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :ueberauth, Ueberauth,
  providers: [
    google: {Ueberauth.Strategy.Google, [default_scope: "emails profile plus.me"]}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
