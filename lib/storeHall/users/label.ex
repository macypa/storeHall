defmodule StoreHall.Users.Label do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :item_id, :label]}
  schema "user_labels" do
    belongs_to :user, StoreHall.Users.User, type: :string
    field :item_id, :integer
    field :label, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(labels, attrs) do
    labels
    |> cast(attrs, [:label, :item_id, :user_id])
    |> validate_required([:label, :item_id, :user_id])
    |> unique_constraint(:label_exists, name: :unique_label)
  end
end
