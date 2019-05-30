defmodule StoreHall.Chats.ChatMessage do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :item_id, :item_owner_id, :details, :user_id, :author_id]}
  schema "chat_messages" do
    field :author_id, :string
    field :item_owner_id, :string
    field :item_id, :integer
    field :details, :map, default: %{}
    field :user_id, :string

    timestamps()
  end

  @doc false
  def changeset(chat_msg, attrs) do
    chat_msg
    |> cast(attrs, [:author_id, :item_id, :item_owner_id, :user_id, :details])
    |> validate_required([:author_id, :item_owner_id, :user_id, :details])
  end
end
