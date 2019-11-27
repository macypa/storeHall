defmodule StoreHall.Users.Reactions do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_reactions" do
    belongs_to :user, StoreHall.Users.User, type: :string
    field :reacted_to, :integer
    field :type, :string
    field :reaction, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(reactions, attrs) do
    reactions
    |> cast(attrs, [:user_id, :reacted_to, :type, :reaction])
    |> validate_required([:user_id, :reacted_to, :type, :reaction])
    |> unique_constraint(:reaction_exists, name: :unique_reaction)
  end
end
