defmodule StoreHall.Comments.UserComment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_comments" do
    field :author_id, :string
    field :comment_id, :integer
    field :details, :map, default: %{}
    field :user_id, :string

    timestamps()
  end

  @doc false
  def changeset(user_comment, attrs) do
    user_comment
    |> cast(attrs, [:author_id, :comment_id, :user_id, :details])
    |> validate_required([:author_id, :user_id, :details])
  end
end
