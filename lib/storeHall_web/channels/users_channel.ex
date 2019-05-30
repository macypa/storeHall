defmodule StoreHallWeb.UsersChannel do
  use Phoenix.Channel

  import Ecto.Query, warn: false
  alias StoreHall.Repo
  alias Ecto.Multi
  alias StoreHall.Ratings
  alias StoreHall.Comments
  alias StoreHall.Chats
  alias StoreHall.Users
  alias StoreHall.Users.Action

  @topic_prefix "/users"

  def topic_prefix() do
    @topic_prefix
  end

  def join(@topic_prefix <> _id, _message, socket) do
    {:ok, socket}
  end

  def handle_in(
        "filter",
        %{"data" => filter},
        socket
      ) do
    filtered = Users.list_users(filter |> Plug.Conn.Query.decode())

    push(socket, "filtered_users", %{filter: filter, filtered: Jason.encode!(filtered)})

    {:reply, :ok, socket}
  end

  def handle_in(
        "msg:add",
        %{"data" => chat_msg},
        socket
      ) do
    case Chats.create_chat_message(chat_msg) do
      {:ok, chat_msg} ->
        broadcast_msg!(
          chat_msg.user_id,
          "new_msg",
          %{
            new_msg: Jason.encode!(chat_msg)
          }
        )

        broadcast_msg!(
          chat_msg.item_owner_id,
          "new_msg",
          %{
            new_msg: Jason.encode!(chat_msg)
          }
        )
    end

    {:reply, :ok, socket}
  end

  def handle_in(
        "comment:add",
        %{"data" => comment},
        socket
      ) do
    case Comments.create_user_comment(comment) do
      {:ok, comment} ->
        broadcast!(
          socket,
          "new_comment",
          %{
            comment_parent_id: comment.comment_id,
            new_comment: Jason.encode!(comment)
          }
        )
    end

    {:reply, :ok, socket}
  end

  def handle_in(
        "rating:add",
        %{"data" => rating},
        socket
      ) do
    case socket.assigns.current_user_id do
      nil ->
        push(socket, "error", %{message: "must be logged in"})

      _logged_user ->
        case Ratings.create_user_rating(rating) do
          {:ok, rating, user_rating} ->
            broadcast!(
              socket,
              "new_rating",
              %{
                new_rating: Jason.encode!(rating)
              }
            )

            broadcast!(socket, "update_rating", %{new_rating: user_rating})

          {:error, _rating} ->
            push(socket, "error", %{
              message: "you already did it :)"
            })
        end
    end

    {:reply, :ok, socket}
  end

  def handle_in(
        "reaction:" <> reaction,
        %{"data" => _data},
        %{topic: @topic_prefix <> "/" <> user_id} = socket
      ) do
    case socket.assigns.current_user_id do
      nil ->
        push(socket, "error", %{message: "must be logged in"})

      _logged_user ->
        Multi.new()
        |> Action.add_relation(user_id, socket.assigns.current_user_id, reaction)
        |> Ratings.update_user_rating(user_id, [Action.reaction_to_rating(reaction)])
        |> Repo.transaction()
        |> case do
          {:ok, multi} ->
            if Map.has_key?(multi, :calc_user_rating) do
              broadcast!(socket, "update_rating", %{new_rating: multi.calc_user_rating})
            end

          {:error, _op, _value, _changes} ->
            push(socket, "error", %{
              message: "you already did it :)"
            })
        end
    end

    {:reply, :ok, socket}
  end

  def broadcast_msg!(user_id, message, body) when is_bitstring(user_id) do
    StoreHallWeb.Endpoint.broadcast!(@topic_prefix <> "/" <> user_id, message, body)
  end

  def broadcast_msg(user_id, message, body) when is_bitstring(user_id) do
    StoreHallWeb.Endpoint.broadcast(@topic_prefix <> "/" <> user_id, message, body)
  end
end
