defmodule StoreHall.Comments.ItemComment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "item_comments" do
    field :comment_id, :integer
    field :details, :map, default: %{}
    field :item_id, :integer
    field :user_id, :string
    field :author_id, :string

    timestamps()
  end

  @doc false
  def changeset(item_comment, attrs) do
    item_comment
    |> cast(attrs, [:item_id, :comment_id, :author_id, :user_id, :details])
    |> validate_required([:author_id, :item_id, :user_id, :details])
  end
end
