defmodule StoreHall.Ratings.UserRating do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :details, :user_id, :author_id]}
  schema "user_ratings" do
    belongs_to :author, StoreHall.Users.User, type: :string
    belongs_to :user, StoreHall.Users.User, type: :string
    field :details, :map, default: %{"scores" => %{}}

    timestamps()
  end

  @doc false
  def changeset(user_rating, attrs) do
    user_rating
    |> cast(attrs, [:author_id, :user_id, :details])
    |> validate_required([:author_id, :user_id, :details])
    |> unique_constraint(:user_rating_exists, name: :unique_user_rating)
  end
end
