defmodule StoreHall.Items.Item do
  use Ecto.Schema
  import Ecto.Changeset
  import StoreHall.ReactionFields

  @derive {Jason.Encoder,
           only:
             [:id, :name, :details, :user_id, :inserted_at, :updated_at] ++
               reaction_jason_fields()}
  schema "items" do
    field :name, :string
    belongs_to :user, StoreHall.Users.User, type: :string

    field :details, :map,
      default: %{
        "price" => 0,
        "description" => "",
        "conditions" => "",
        "expiration" => "",
        "features" => %{},
        "images" => [],
        "videos" => [],
        "tags" => [],
        "cities" => [],
        "rating" => %{"count" => 0, "score" => -1},
        "comments_count" => 0
      }

    has_many :comments, StoreHall.Comments.ItemComment
    has_many :ratings, StoreHall.Ratings.ItemRating
    has_many :messages, StoreHall.Chats.ChatMessage

    reaction_fields()

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:name, :user_id, :details])
    |> validate_required([:name, :user_id, :details])
    |> validate_required_details(["price"])
    |> validate_length(:name, max: 255)
    |> unique_constraint(:not_unique_name_for_user, name: :unique_name_for_user)
    |> StoreHall.Images.validate_images(:details)
  end

  def validate_required_details(changeset, details_fields, options \\ []) do
    details_fields
    |> Enum.reduce(changeset, fn field, acc ->
      validate_change(acc, :details, fn _, details ->
        details[field]
        |> case do
          "" -> [{:details, options[:message] || "#{field} can't be empty"}]
          _ -> []
        end
      end)
    end)
  end

  def slug_id(item) do
    "#{item.id}-#{Slug.slugify(item.name)}"
  end
end

defimpl Phoenix.Param, for: StoreHall.Items.Item do
  def to_param(item = %{id: _id, name: _name}) do
    StoreHall.Items.Item.slug_id(item)
  end
end
