defmodule StoreHall.Comments.ItemComment do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [
             :id,
             :comment_id,
             :details,
             :item_id,
             :user_id,
             :author_id,
             :inserted_at,
             :updated_at,
             :author,
             :reactions,
             :lolz_count,
             :wowz_count,
             :mehz_count,
             :alertz_count
           ]}
  schema "item_comments" do
    belongs_to :author, StoreHall.Users.User, type: :string
    belongs_to :user, StoreHall.Users.User, type: :string
    field :item_id, :integer
    field :comment_id, :integer
    field :details, :map, default: %{}

    field :lolz_count, :integer, virtual: true
    field :wowz_count, :integer, virtual: true
    field :mehz_count, :integer, virtual: true
    field :alertz_count, :integer, virtual: true

    has_many :reactions, StoreHall.Users.Reactions,
      foreign_key: :reacted_to,
      where: [type: "comment"]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(item_comment, attrs) do
    item_comment
    |> cast(attrs, [:item_id, :comment_id, :author_id, :user_id, :details])
    |> validate_required([:item_id, :user_id, :details])
  end
end
