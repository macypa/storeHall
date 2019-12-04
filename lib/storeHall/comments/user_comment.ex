defmodule StoreHall.Comments.UserComment do
  use Ecto.Schema
  import Ecto.Changeset
  import StoreHall.ReactionFields

  @derive {Jason.Encoder,
           only:
             [
               :id,
               :comment_id,
               :details,
               :user_id,
               :author_id,
               :inserted_at,
               :updated_at,
               :author
             ] ++
               reaction_jason_fields()}
  schema "user_comments" do
    belongs_to :author, StoreHall.Users.User, type: :string
    belongs_to :user, StoreHall.Users.User, type: :string
    field :comment_id, :integer
    field :details, :map, default: %{}

    reaction_fields("comment")

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_comment, attrs) do
    user_comment
    |> cast(attrs, [:author_id, :comment_id, :user_id, :details])
    |> validate_required([:user_id, :details])
  end
end
