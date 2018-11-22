defmodule StoreHall.Users.Ratings do
  use Ecto.Schema
  import Ecto.Changeset


  schema "user_ratings" do
    field :content, :map
    field :from_user_id, :integer
    field :parent_rating_id, :integer
    field :type, :string
    field :user_id, :integer

    timestamps()
  end

  @doc false
  def changeset(ratings, attrs) do
    ratings
    |> cast(attrs, [:user_id, :type, :parent_rating_id, :from_user_id, :content])
    |> validate_required([:user_id, :type, :parent_rating_id, :from_user_id, :content])
  end
end
