defmodule StoreHall.Users.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, []}
  @derive {Phoenix.Param, key: :id}
  schema "users" do
    field :email, :string, unique: true
    field :first_name, :string
    field :last_name, :string
    field :image, :string, default: ""
    field :provider, :string
    field :details, :map, default: %{"rating" => %{"count" => 0, "score" => -1}}

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :email, :image, :provider, :details])
    |> validate_required([:first_name, :email, :provider, :details])
    |> unique_constraint(:email)
  end
end
