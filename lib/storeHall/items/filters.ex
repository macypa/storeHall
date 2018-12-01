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
    |> unique_constraint(:item_filters, name: :name_type_index)
  end

  def to_map(data) do
    Enum.reduce(data, %{}, fn data, acc ->
      acc
      |> Map.put_new(data.type, %{})
      |> put_in([data.type, data.name], data.count)
    end)
  end
end
