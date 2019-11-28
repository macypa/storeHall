defmodule StoreHall.Ratings.ItemRating do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [
             :id,
             :details,
             :item_id,
             :user_id,
             :author_id,
             :inserted_at,
             :updated_at,
             :author
           ]}
  schema "item_ratings" do
    belongs_to :author, StoreHall.Users.User, type: :string
    belongs_to :user, StoreHall.Users.User, type: :string
    field :item_id, :integer
    field :rating_id, :integer
    field :details, :map, default: %{"scores" => %{}}

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(item_rating, attrs) do
    item_rating
    |> cast(attrs, [:author_id, :item_id, :rating_id, :user_id, :details])
    |> validate_required([:author_id, :item_id, :user_id, :details])
    |> unique_constraint(:item_rating_exists, name: :unique_item_rating)
  end
end
