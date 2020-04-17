defmodule StoreHall.Chats do
  import Ecto.Query, warn: false
  alias StoreHall.Repo
  alias Ecto.Multi

  alias StoreHall.Chats.ChatMessage
  alias StoreHall.Items.Item
  alias StoreHall.Users
  alias StoreHall.Users.User

  def for_chat_room_query(nil, owner_id, user_id) do
    ChatMessage
    |> where(owner_id: ^owner_id)
    |> where(user_id: ^user_id)
  end

  def for_chat_room_query(item_id, owner_id, user_id) do
    ChatMessage
    |> where(item_id: ^item_id)
    |> where(owner_id: ^owner_id)
    |> where(user_id: ^user_id)
  end

  def for_chat_room(item_id, owner_id, user_id) do
    for_chat_room_query(item_id, owner_id, user_id)
    |> Repo.all()
  end

  def for_item(id, user_id) do
    ChatMessage
    |> where(item_id: ^id)
    |> where(user_id: ^user_id)
    |> Repo.all()
  end

  def for_user(id, user_id) do
    ChatMessage
    |> where(
      [c],
      is_nil(c.item_id) and c.owner_id == ^id and c.user_id == ^user_id
    )
    |> Repo.all()
  end

  def all_msgs_for_user(id) do
    ChatMessage
    |> where(user_id: ^id)
    |> or_where(owner_id: ^id)
    |> Repo.all()
  end

  def preload_author(chat) do
    chat
    |> Users.preload_author(Repo)
  end

  def preload_for(item_user, user_id) do
    item_user
    |> Map.put(
      :messages,
      item_user |> construct_topics(user_id)
    )
  end

  defp assoc_chats(item_user = %Item{}, user_id) do
    for_item(item_user.id, user_id)
  end

  defp assoc_chats(item_user = %User{}, user_id) do
    if item_user.id == user_id do
      all_msgs_for_user(user_id)
    else
      for_user(item_user.id, user_id)
    end
  end

  def construct_topics(item_user, user_id) do
    case user_id do
      nil ->
        %{}

      -1 ->
        %{}

      user_id ->
        assoc_chats(item_user, user_id)
        |> Enum.reduce(%{}, fn chat, acc ->
          coresponder_id =
            if user_id == chat.user_id do
              chat.owner_id
            else
              chat.user_id
            end

          item_ids =
            case get_in(acc, [coresponder_id]) do
              nil -> []
              item_ids -> item_ids
            end

          acc =
            acc
            |> Map.put_new(coresponder_id, [])

          acc
          |> put_in([coresponder_id], (item_ids ++ [chat.item_id]) |> Enum.uniq())
        end)
    end
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

  def delete_chat_room(item_id, owner_id, user_id, repo \\ Repo) do
    Multi.new()
    |> Multi.delete_all(:delete_chat_room, for_chat_room_query(item_id, owner_id, user_id))
    |> repo.transaction()
    |> case do
      {:ok, multi} ->
        {:ok, multi.delete_chat_room}

      {:error, _op, value, _changes} ->
        {:error, value}
    end
  end
end
