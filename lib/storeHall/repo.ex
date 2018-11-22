defmodule StoreHall.Repo do
  use Ecto.Repo,
    otp_app: :storeHall,
    adapter: Ecto.Adapters.Postgres
end
