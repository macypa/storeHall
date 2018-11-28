defmodule StoreHall.Users.Relations do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_relations" do
    field :related_to_user_id, :string
    field :type, :string
    field :user_id, :string

    timestamps()
  end

  @doc false
  def changeset(relations, attrs) do
    relations
    |> cast(attrs, [:user_id, :related_to_user_id, :type])
    |> validate_required([:user_id, :related_to_user_id, :type])
  end
end
