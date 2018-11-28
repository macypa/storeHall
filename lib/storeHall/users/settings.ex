defmodule StoreHall.Users.Settings do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_settings" do
    field :user_id, :string
    field :settings, :map, default: %{}

    timestamps()
  end

  @doc false
  def changeset(settings, attrs) do
    settings
    |> cast(attrs, [:user_id, :settings])
    |> validate_required([:user_id, :settings])
  end
end
