defmodule StoreHall.Ratings.ItemRating do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :details, :item_id, :user_id, :author_id]}
  schema "item_ratings" do
    field :author_id, :string
    field :details, :map, default: %{"scores" => %{}}
    field :item_id, :integer
    field :user_id, :string

    timestamps()
  end

  @doc false
  def changeset(item_rating, attrs) do
    item_rating
    |> cast(attrs, [:author_id, :item_id, :user_id, :details])
    |> validate_required([:author_id, :item_id, :user_id, :details])
    |> unique_constraint(:item_rating_exists, name: :unique_item_rating)
  end
end
