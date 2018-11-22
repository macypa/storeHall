defmodule StoreHall.Items.Filters do
  use Ecto.Schema
  import Ecto.Changeset


  schema "item_filters" do
    field :list, :map
    field :type, :string

    timestamps()
  end

  @doc false
  def changeset(filters, attrs) do
    filters
    |> cast(attrs, [:type, :list])
    |> validate_required([:type, :list])
  end
end
