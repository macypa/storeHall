defmodule StoreHall.Items.Ratings do
  use Ecto.Schema
  import Ecto.Changeset


  schema "item_ratings" do
    field :content, :map
    field :from_user_id, :integer
    field :item_id, :integer
    field :parent_rating_id, :integer
    field :type, :string

    timestamps()
  end

  @doc false
  def changeset(ratings, attrs) do
    ratings
    |> cast(attrs, [:item_id, :type, :parent_rating_id, :from_user_id, :content])
    |> validate_required([:item_id, :type, :parent_rating_id, :from_user_id, :content])
  end
end
