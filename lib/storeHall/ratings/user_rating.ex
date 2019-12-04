defmodule StoreHall.Ratings.UserRating do
  use Ecto.Schema
  import Ecto.Changeset
  import StoreHall.ReactionFields

  @derive {Jason.Encoder,
           only:
             [:id, :details, :user_id, :author_id, :inserted_at, :updated_at, :author] ++
               reaction_jason_fields()}
  schema "user_ratings" do
    belongs_to :author, StoreHall.Users.User, type: :string
    belongs_to :user, StoreHall.Users.User, type: :string
    field :rating_id, :integer
    field :details, :map, default: %{"scores" => %{}}

    reaction_fields("rating")

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_rating, attrs) do
    user_rating
    |> cast(attrs, [:author_id, :rating_id, :user_id, :details])
    |> validate_required([:author_id, :user_id, :details])
    |> unique_constraint(:user_rating_exists, name: :unique_user_rating)
  end
end
