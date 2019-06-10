defmodule StoreHall.Items.Item do
  use Ecto.Schema

  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :name, :details, :user_id]}
  schema "items" do
    field :name, :string
    belongs_to :user, StoreHall.Users.User, type: :string

    field :details, :map,
      default: %{
        "tags" => [],
        "images" => [],
        "rating" => %{"count" => 0, "score" => -1},
        "comments_count" => 0
      }

    has_many :comments, StoreHall.Comments.ItemComment
    has_many :ratings, StoreHall.Ratings.ItemRating
    has_many :messages, StoreHall.Chats.ChatMessage

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

defimpl Phoenix.Param, for: StoreHall.Items.Item do
  def to_param(%{id: id, name: name}) do
    "#{id}-#{Slug.slugify(name)}"
  end
end
