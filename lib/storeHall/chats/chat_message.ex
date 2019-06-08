defmodule StoreHall.Chats.ChatMessage do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :item_id, :owner_id, :details, :user_id, :author_id]}
  schema "chat_messages" do
    belongs_to :author, StoreHall.Users.User, type: :string
    belongs_to :user, StoreHall.Users.User, type: :string
    belongs_to :owner, StoreHall.Users.User, type: :string
    field :item_id, :integer
    field :details, :map, default: %{}

    timestamps()
  end

  @doc false
  def changeset(chat_msg, attrs) do
    chat_msg
    |> cast(attrs, [:author_id, :item_id, :owner_id, :user_id, :details])
    |> validate_required([:author_id, :owner_id, :user_id, :details])
  end
end
