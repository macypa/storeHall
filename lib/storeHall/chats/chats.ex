defmodule StoreHall.Chats do
  import Ecto.Query, warn: false
  alias StoreHall.Repo
  alias Ecto.Multi

  alias StoreHall.Chats.ChatMessage

  def for_item(id, user_id) do
    ChatMessage
    |> where(item_id: ^id)
    |> where(user_id: ^to_string(user_id))
    |> Repo.all()
  end

  def for_user(user_id) do
    ChatMessage
    |> where(
      [c],
      is_nil(c.item_id) and
        (c.user_id == ^user_id or
           c.owner_id == ^user_id)
    )
    |> Repo.all()
  end

  def all_msgs_for_user(id) do
    ChatMessage
    |> where(user_id: ^id)
    |> or_where(owner_id: ^id)
    |> Repo.all()
  end

  def for_item_sorted_by_topic(id, user_id) do
    for_item(id, user_id)
    |> sorte_by_topic(user_id)
  end

  def for_user_sorted_by_topic(id, current_id) do
    if id == current_id do
      all_msgs_for_user(current_id)
    else
      for_user(id)
    end
    |> sorte_by_topic(id)
  end

  def sorte_by_topic(chats, id) do
    chats
    |> Enum.reduce(%{}, fn chat, acc ->
      coresponder_id =
        if id == chat.user_id do
          chat.owner_id
        else
          if id == chat.owner_id do
            chat.user_id
          end
        end

      msgs =
        case get_in(acc, [coresponder_id, chat.item_id]) do
          nil -> []
          msgs -> msgs
        end

      acc =
        acc
        |> Map.put_new(coresponder_id, %{})

      acc
      |> put_in([coresponder_id, chat.item_id], msgs ++ [chat])
    end)
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
