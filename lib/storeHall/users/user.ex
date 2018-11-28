defmodule StoreHall.Users.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, []}
  @derive {Phoenix.Param, key: :id}
  schema "users" do
    field :email, :string, unique: true
    field :first_name, :string
    field :last_name, :string
    field :provider, :string
    field :user_settings_id, :string

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :email, :provider, :user_settings_id])
    |> validate_required([:first_name, :email, :provider])
  end
end
