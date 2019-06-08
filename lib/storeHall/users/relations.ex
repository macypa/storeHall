defmodule StoreHall.Users.Relations do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_relations" do
    belongs_to :related_to_user, StoreHall.Users.User, type: :string
    belongs_to :user, StoreHall.Users.User, type: :string
    field :type, :string

    timestamps()
  end

  @doc false
  def changeset(relations, attrs) do
    relations
    |> cast(attrs, [:user_id, :related_to_user_id, :type])
    |> validate_required([:user_id, :related_to_user_id, :type])
    |> unique_constraint(:relation_exists, name: :unique_relation)
  end
end
