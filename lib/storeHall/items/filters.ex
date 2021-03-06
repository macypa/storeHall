defmodule StoreHall.Items.Filters do
  use Ecto.Schema
  import Ecto.Changeset

  schema "item_filters" do
    field :count, :integer
    field :name, :string
    field :type, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(filters, attrs) do
    filters
    |> cast(attrs, [:name, :type, :count])
    |> validate_required([:name, :type, :count])
    |> unique_constraint(:item_filters, name: :name_type_index)
  end

  @empty_map %{"merchant" => %{}, "tags" => %{}, "cities" => %{}}
  def to_map(data, min_count \\ 10) do
    case data do
      [] ->
        @empty_map

      data ->
        Enum.reduce(data, @empty_map, fn data, acc ->
          case data.type do
            type when type == "merchant" ->
              acc
              |> put_in([data.type, data.name], data.count)

            _ ->
              case data.count do
                count when count < min_count ->
                  acc

                _ ->
                  acc
                  |> put_in([data.type, data.name], data.count)
              end
          end
        end)
    end
  end
end
