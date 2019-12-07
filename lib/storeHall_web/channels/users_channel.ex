defmodule StoreHallWeb.UsersChannel do
  use Phoenix.Channel

  require StoreHallWeb.Gettext
  alias StoreHallWeb.Gettext, as: Gettext

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

  defp decode_filter(filter) do
    filter
    |> Plug.Conn.Query.decode()
    |> Map.merge(%{"id" => Application.get_env(:storeHall, :about)[:user_id]})
  end

  def join("/about" <> _id, _message, socket) do
    {:ok, socket}
  end

  def join(@topic_prefix <> _id, _message, socket) do
    {:ok, socket}
  end

  def handle_in(
        "filter",
        %{"data" => filter, "page_for" => "comments" <> _},
        socket
      ) do
    filtered =
      Comments.list_comments(
        Users,
        socket.assigns.current_user_id,
        filter |> decode_filter
      )

    push(socket, "filtered_comments", %{filter: filter, filtered: Jason.encode!(filtered)})

    {:reply, :ok, socket}
  end

  def handle_in(
        "filter",
        %{"data" => filter, "page_for" => "ratings" <> _},
        socket
      ) do
    filtered =
      Ratings.list_ratings(
        Users,
        socket.assigns.current_user_id,
        filter |> decode_filter
      )

    push(socket, "filtered_ratings", %{filter: filter, filtered: Jason.encode!(filtered)})

    {:reply, :ok, socket}
  end

  def handle_in(
        "filter",
        %{"data" => filter, "show_for" => "comment" <> _},
        socket
      ) do
    filtered =
      Comments.list_comments(
        Users,
        socket.assigns.current_user_id,
        filter |> decode_filter
      )

    push(socket, "show_for_comment", %{filter: filter, filtered: Jason.encode!(filtered)})

    {:reply, :ok, socket}
  end

  def handle_in(
        "filter",
        %{"data" => filter, "show_for" => "rating" <> _},
        socket
      ) do
    filtered =
      Ratings.list_ratings(
        Users,
        socket.assigns.current_user_id,
        filter |> decode_filter
      )

    push(socket, "show_for_rating", %{filter: filter, filtered: Jason.encode!(filtered)})

    {:reply, :ok, socket}
  end

  def handle_in(
        "filter",
        %{"data" => filter},
        socket
      ) do
    filtered = Users.list_users(filter |> decode_filter)

    push(socket, "filtered_users", %{filter: filter, filtered: Jason.encode!(filtered)})

    {:reply, :ok, socket}
  end

  def handle_in(
        "msg:load_chat_room",
        %{"data" => chat_msg},
        socket
      ) do
    case socket.assigns.current_user_id do
      nil ->
        push(socket, "error", %{message: Gettext.gettext("must be logged in")})

      logged_user ->
        unless logged_user != chat_msg["owner_id"] and
                 logged_user != chat_msg["user_id"] do
          chats_for_room =
            Chats.for_chat_room(chat_msg["item_id"], chat_msg["owner_id"], chat_msg["user_id"])
            |> Chats.preload_author()

          push(socket, "chats_for_room", %{chats_for_room: Jason.encode!(chats_for_room)})
        end
    end

    {:reply, :ok, socket}
  end

  def handle_in(
        "msg:delete_chat_room",
        %{"data" => chat_msg},
        socket
      ) do
    case socket.assigns.current_user_id do
      nil ->
        push(socket, "error", %{message: Gettext.gettext("must be logged in")})

      logged_user ->
        unless logged_user != chat_msg["owner_id"] and
                 logged_user != chat_msg["user_id"] do
          Chats.delete_chat_room(chat_msg["item_id"], chat_msg["owner_id"], chat_msg["user_id"])
        end
    end

    {:reply, :ok, socket}
  end

  def handle_in(
        "msg:add",
        %{"data" => chat_msg},
        socket
      ) do
    case socket.assigns.current_user_id do
      nil ->
        push(socket, "error", %{message: Gettext.gettext("must be logged in")})

      logged_user ->
        case Chats.create_chat_message(chat_msg |> Map.put("author_id", logged_user)) do
          {:ok, chat_msg} ->
            chat_msg = chat_msg |> Chats.preload_author()

            broadcast_msg!(
              chat_msg.user_id,
              "new_msg",
              %{
                new_msg: Jason.encode!(chat_msg)
              }
            )

            broadcast_msg!(
              chat_msg.owner_id,
              "new_msg",
              %{
                new_msg: Jason.encode!(chat_msg)
              }
            )
        end
    end

    {:reply, :ok, socket}
  end

  def handle_in(
        "comment:add",
        %{"data" => comment},
        socket
      ) do
    case socket.assigns.current_user_id do
      nil ->
        push(socket, "error", %{message: Gettext.gettext("must be logged in")})

      logged_user ->
        case Comments.create_user_comment(comment |> Map.put("author_id", logged_user)) do
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
        push(socket, "error", %{message: Gettext.gettext("must be logged in")})

      logged_user ->
        case Ratings.validate_scores(rating["details"]["scores"]) do
          false ->
            push(socket, "error", %{
              message:
                Gettext.gettext("All Scores absolute values should add up to max %{max_score} !",
                  max_score: Ratings.max_scores_sum_points()
                )
            })

          true ->
            case Ratings.create_user_rating(rating |> Map.put("author_id", logged_user)) do
              {:ok, rating} ->
                broadcast!(
                  socket,
                  "new_rating",
                  %{
                    rating_parent_id: rating.rating_id,
                    new_rating: Jason.encode!(rating)
                  }
                )

              {:ok, rating, user_rating} ->
                broadcast!(
                  socket,
                  "new_rating",
                  %{
                    rating_parent_id: rating.rating_id,
                    new_rating: Jason.encode!(rating)
                  }
                )

                broadcast!(socket, "update_rating", %{new_rating: user_rating})

              {:error, _rating} ->
                push(socket, "error", %{
                  message: Gettext.gettext("you already did it :)")
                })
            end
        end
    end

    {:reply, :ok, socket}
  end

  def handle_in(
        "reaction:" <> reaction,
        %{"data" => data},
        socket
      ) do
    case socket.assigns.current_user_id do
      nil ->
        push(socket, "error", %{message: Gettext.gettext("must be logged in")})

      logged_user ->
        %{"id" => reacted_to, "author_id" => author_id, "type" => type} = Jason.decode!(data)

        Multi.new()
        |> Action.toggle_or_change_reaction(
          reacted_to,
          logged_user,
          type,
          reaction,
          &update_user_rating_fun/3,
          author_id
        )
        # |> Ratings.update_user_rating(author_id, [Action.reaction_to_rating(reaction)])
        |> Repo.transaction()
        |> case do
          {:ok, multi} ->
            broadcast!(socket, "update_rating", %{
              new_rating: multi.update_rating_for_reaction.calc_user_rating
            })

            push(socket, "reaction_persisted", %{data: data, reaction: reaction})

          {:error, _op, _value, _changes} ->
            push(socket, "error", %{
              message: Gettext.gettext("you already did it :)")
            })
        end
    end

    {:reply, :ok, socket}
  end

  def update_user_rating_fun(repo, author_id, reaction) do
    case author_id do
      item_id when is_integer(item_id) ->
        Multi.new()
        |> Ratings.update_item_rating(item_id, reaction)
        |> repo.transaction()

      user_id when is_binary(user_id) ->
        Multi.new()
        |> Ratings.update_user_rating(user_id, reaction)
        |> repo.transaction()
    end
  end

  def broadcast_msg!(user_id, message, body) when is_bitstring(user_id) do
    StoreHallWeb.Endpoint.broadcast!(@topic_prefix <> "/" <> user_id, message, body)
  end

  def broadcast_msg(user_id, message, body) when is_bitstring(user_id) do
    StoreHallWeb.Endpoint.broadcast(@topic_prefix <> "/" <> user_id, message, body)
  end
end
