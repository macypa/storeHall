defmodule StoreHall.Items.Item do
  use Ecto.Schema
  use Filterable.Phoenix.Model

  import Ecto.Changeset

  filterable(StoreHall.Items.ItemFilterable)

  schema "items" do
    field :name, :string
    field :user_id, :string

    field :details, :map,
      default: %{"tags" => [], "rating" => %{"count" => 0, "score" => -1}, "comments_count" => 0}

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
