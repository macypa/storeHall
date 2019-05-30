defmodule StoreHall.Chats do
  import Ecto.Query, warn: false
  alias StoreHall.Repo
  alias Ecto.Multi

  alias StoreHall.Chats.ChatMessage

  def for_item(id) do
    ChatMessage
    |> where(item_id: ^id)
    |> Repo.all()
  end

  def for_user(id) do
    ChatMessage
    |> where(user_id: ^id)
    |> or_where(item_owner_id: ^id)
    |> Repo.all()
  end

  def create_chat_message(chat_msg \\ %{}, repo \\ Repo) do
    Multi.new()
    |> Multi.insert(:insert, ChatMessage.changeset(%ChatMessage{}, chat_msg))
    |> repo.transaction()
    |> case do
      {:ok, multi} ->
        {:ok, multi.insert}

      {:error, _op, value, _changes} ->
        {:error, value}
    end
  end
end
