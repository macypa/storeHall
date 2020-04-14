defmodule StoreHall.Users.User do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :id,
    :email,
    :name,
    :image,
    :details,
    :info,
    :marketing_info,
    :provider,
    :inserted_at,
    :updated_at
  ]

  @primary_key {:id, :string, []}
  @derive {Phoenix.Param, key: :id}
  @derive {Jason.Encoder, only: @fields}
  schema "users" do
    field :email, :string, unique: true
    field :name, :string
    field :image, :string, default: ""
    field :provider, :string

    field :details, :map,
      default: %{
        "merchant_type" => "merch_private",
        "images" => [],
        "rating" => %{"count" => 0, "score" => 0},
        "comments_count" => 0
      }

    field :info, :map,
      default: %{
        "videos" => [],
        "address" => [],
        "contacts" => [],
        "mail" => [],
        "web" => [],
        "open" => [],
        "description" => ""
      }

    field :marketing_info, :map,
      default: %{
        "marketing_consent" => "not_agreed",
        "mail_credits_ask" => 10
      }

    has_many :items, StoreHall.Items.Item
    has_many :comments, StoreHall.Comments.UserComment
    has_many :ratings, StoreHall.Ratings.UserRating
    has_many :messages, StoreHall.Chats.ChatMessage

    field :lolz_count, :integer, virtual: true
    field :wowz_count, :integer, virtual: true
    field :mehz_count, :integer, virtual: true
    field :alertz_count, :integer, virtual: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :image, :provider, :details, :info, :marketing_info])
    |> validate_required([:name, :email, :provider, :details])
    |> unique_constraint(:email)
    |> StoreHall.Images.validate_images(:details)
  end

  def fields(), do: @fields
end
