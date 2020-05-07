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
  alias StoreHall.Marketing.Mails

  @topic_prefix "/users"

  def topic_prefix() do
    @topic_prefix
  end

  defp decode_filter(filter) do
    %{"id" => Application.get_env(:storeHall, :about)[:user_id]}
    |> Map.merge(
      filter
      |> Plug.Conn.Query.decode()
    )
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
        %{"data" => filter, "page_for" => "mails" <> _},
        socket
      ) do
    filtered =
      Mails.all_mails(
        filter |> decode_filter,
        socket.assigns.current_user_id
      )

    push(socket, "filtered_mails", %{filter: filter, filtered: Jason.encode!(filtered)})

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
        filter
        |> decode_filter
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
    filtered = Users.list_users(filter |> decode_filter, socket.assigns.current_user_id)

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

      logged_user_id ->
        unless logged_user_id != chat_msg["owner_id"] and
                 logged_user_id != chat_msg["user_id"] do
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

      logged_user_id ->
        unless logged_user_id != chat_msg["owner_id"] and
                 logged_user_id != chat_msg["user_id"] do
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

      logged_user_id ->
        case Chats.create_chat_message(chat_msg |> Map.put("author_id", logged_user_id)) do
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
        "marketing-mail:add",
        %{"filter_params" => filter, "mail_params" => mail_params},
        socket
      ) do
    case socket.assigns.current_user_id do
      nil ->
        push(socket, "error", %{message: Gettext.gettext("must be logged in")})

      logged_user_id ->
        # Mails.list_mails(%{}, [socket.assigns.current_user_id])
        # |> hd
        # |> Mails.remove_user_id_from_mail(logged_user_id)

        filtered_ids = Users.list_user_ids(filter |> decode_filter, logged_user_id)

        mail_params
        |> decode_filter
        |> Map.get("mail")
        |> Map.put("to_users", filtered_ids)
        |> Map.put("from_user_id", logged_user_id)
        |> Mails.create_mail()
        |> case do
          {:ok, mail} ->
            mail = mail |> Mails.preload_sender()

            filtered_ids
            |> Enum.each(fn to_user_id ->
              broadcast_msg!(
                to_user_id,
                "new_mail",
                %{
                  new_mail: Jason.encode!(mail)
                }
              )
            end)

            push(socket, "mail_sent", %{
              message: Gettext.gettext("mail sent.")
            })

          {:error, _} ->
            push(socket, "error", %{
              message: Gettext.gettext("mail not sent!")
            })
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

      logged_user_id ->
        case Comments.create_user_comment(comment |> Map.put("author_id", logged_user_id)) do
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

      logged_user_id ->
        unless logged_user_id == rating["user_id"] do
          case Ratings.validate_scores(rating) do
            false ->
              push(socket, "error", %{
                message:
                  Gettext.gettext(
                    "All Scores absolute values should add up to max %{max_score} !",
                    max_score: Ratings.max_scores_sum_points()
                  )
              })

            true ->
              case Ratings.upsert_user_rating(rating |> Map.put("author_id", logged_user_id)) do
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

                  broadcast_updated_rating_user(rating.user_id, user_rating)

                {:error, _rating} ->
                  push(socket, "error", %{
                    message: Gettext.gettext("Something unexpected happened")
                  })
              end
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

      logged_user_id ->
        %{"id" => reacted_to, "user_id" => user_id, "author_id" => author_id, "type" => type} =
          Jason.decode!(data)

        unless logged_user_id == user_id do
          Multi.new()
          |> Action.toggle_or_change_reaction(
            reacted_to,
            logged_user_id,
            author_id,
            type,
            reaction
          )
          # |> Ratings.update_user_rating(author_id, [Action.reaction_to_rating(reaction)])
          |> Repo.transaction()
          |> case do
            {:ok, multi} ->
              push(socket, "reaction_persisted", %{data: data, reaction: reaction})

              broadcast_updated_rating_user(multi.update_rating_for_reaction)
              broadcast_updated_rating_item(multi.update_rating_for_reaction)

            {:error, _op, _value, _changes} ->
              push(socket, "error", %{
                message: Gettext.gettext("you already did it :)")
              })
          end
        end
    end

    {:reply, :ok, socket}
  end

  defp broadcast_updated_rating_user(multi) do
    broadcast_updated_rating_user(multi.user.id, multi.calc_user_rating)
  end

  def broadcast_updated_rating_user(user_id, rating) do
    StoreHallWeb.Endpoint.broadcast_from!(self(), topic_prefix(), "update_rating", %{
      new_rating: rating,
      for_user_id: user_id
    })

    user_room = topic_prefix() <> "/" <> user_id

    StoreHallWeb.Endpoint.broadcast_from!(self(), user_room, "update_rating", %{
      new_rating: rating,
      for_user_id: user_id
    })
  end

  defp broadcast_updated_rating_item(multi) do
    broadcast_updated_rating_item(multi.item, multi.calc_item_rating)
  end

  def broadcast_updated_rating_item(item, rating) do
    item_id = to_string(item.id)
    item_room = StoreHallWeb.ItemsChannel.topic_prefix()

    StoreHallWeb.Endpoint.broadcast_from!(self(), item_room, "update_rating", %{
      new_rating: rating,
      for_id: item_id
    })

    item_room = StoreHallWeb.ItemsChannel.topic_prefix() <> "/" <> item_id

    StoreHallWeb.Endpoint.broadcast_from!(self(), item_room, "update_rating", %{
      new_rating: rating,
      for_id: item_id
    })
  end

  def broadcast_msg!(user_id, message, body) when is_bitstring(user_id) do
    StoreHallWeb.Endpoint.broadcast!(@topic_prefix <> "/" <> user_id, message, body)
  end

  def broadcast_msg(user_id, message, body) when is_bitstring(user_id) do
    StoreHallWeb.Endpoint.broadcast(@topic_prefix <> "/" <> user_id, message, body)
  end
end
