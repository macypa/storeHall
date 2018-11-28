defmodule StoreHall.Items.Filters do
  use Ecto.Schema
  import Ecto.Changeset


  schema "item_filters" do
    field :count, :integer
    field :name, :string
    field :type, :string

    timestamps()
  end

  @doc false
  def changeset(filters, attrs) do
    filters
    |> cast(attrs, [:name, :type, :count])
    |> validate_required([:name, :type, :count])
  end
end
