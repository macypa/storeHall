defmodule StoreHall.Users.Labels do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_labels" do
    belongs_to :user, StoreHall.Users.User, type: :string
    field :item_id, :integer
    field :label, :string

    timestamps()
  end

  @doc false
  def changeset(labels, attrs) do
    labels
    |> cast(attrs, [:label, :item_id, :user_id])
    |> validate_required([:label, :item_id, :user_id])
    |> unique_constraint(:label_exists, name: :unique_label)
  end
end
