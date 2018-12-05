defmodule StoreHall.Items.Item do
  use Ecto.Schema
  import Ecto.Changeset

  schema "items" do
    field :details, :map, default: %{}
    field :name, :string
    field :user_id, :string

    timestamps()
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:name, :user_id, :details])
    |> validate_required([:name, :user_id, :details])
    |> unique_constraint(:not_unique_name_for_user, name: :unique_name_for_user)
  end
end
