defmodule StoreHall.Ratings.UserRating do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Poison.Encoder, only: [:id, :details, :user_id, :author_id]}
  schema "user_ratings" do
    field :author_id, :string
    field :details, :map, default: %{"scores" => %{}}
    field :user_id, :string

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
