defmodule StoreHall.Users.Labels do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_labels" do
    field :item_id, :integer
    field :label, :string
    field :user_id, :string

    timestamps()
  end

  @doc false
  def changeset(labels, attrs) do
    labels
    |> cast(attrs, [:label, :item_id, :user_id])
    |> validate_required([:label, :item_id, :user_id])
  end
end
