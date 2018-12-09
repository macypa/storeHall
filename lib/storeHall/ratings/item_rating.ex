defmodule StoreHall.Ratings.ItemRating do
  use Ecto.Schema
  import Ecto.Changeset

  schema "item_ratings" do
    field :author_id, :string
    field :details, :map, default: %{}
    field :item_id, :integer
    field :rating_id, :integer
    field :user_id, :string

    timestamps()
  end

  @doc false
  def changeset(item_rating, attrs) do
    item_rating
    |> cast(attrs, [:author_id, :item_id, :rating_id, :user_id, :details])
    |> validate_required([:author_id, :item_id, :user_id, :details])
  end
end
