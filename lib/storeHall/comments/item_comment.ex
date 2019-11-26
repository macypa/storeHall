defmodule StoreHall.Comments.ItemComment do
  use Ecto.Schema
  import Ecto.Changeset

  # @derive {Jason.Encoder, except: [:__meta__, :__struct__]}
  # only: [
  #   :id,
  #   :comment_id,
  #   :details,
  #   :item_id,
  #   :user_id,
  #   :author_id,
  #   :inserted_at,
  #   :updated_at,
  #   :author,
  #   :user
  # ]}
  schema "item_comments" do
    belongs_to :author, StoreHall.Users.User, type: :string
    belongs_to :user, StoreHall.Users.User, type: :string
    field :item_id, :integer
    field :comment_id, :integer
    field :details, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(item_comment, attrs) do
    item_comment
    |> cast(attrs, [:item_id, :comment_id, :author_id, :user_id, :details])
    |> validate_required([:item_id, :user_id, :details])
  end
end
