defmodule StoreHall.Ratings.UserRating do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_ratings" do
    field :author_id, :string
    field :details, :map, default: %{"scores" => %{}}
    field :rating_id, :integer
    field :user_id, :string

    timestamps()
  end

  @doc false
  def changeset(user_rating, attrs) do
    user_rating
    |> cast(attrs, [:author_id, :rating_id, :user_id, :details])
    |> validate_required([:author_id, :user_id, :details])
  end
end
