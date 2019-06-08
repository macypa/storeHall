defmodule StoreHallWeb.ItemsChannel do
  use Phoenix.Channel

  import Ecto.Query, warn: false
  alias StoreHall.Repo
  alias Ecto.Multi
  alias StoreHall.Ratings
  alias StoreHall.Comments
  alias StoreHall.Items
  alias StoreHall.Users.Action

  @topic_prefix "/items"

  def topic_prefix() do
    @topic_prefix
  end

  def join(@topic_prefix <> _id, _message, socket) do
    {:ok, socket}
  end

  def handle_in(
        "filter",
        %{"data" => filter, "page_more" => "comments" <> _},
        socket
      ) do
    filtered = Comments.list_comments(Items, filter |> Plug.Conn.Query.decode())

    push(socket, "filtered_comments", %{filter: filter, filtered: Jason.encode!(filtered)})

    {:reply, :ok, socket}
  end

  def handle_in(
        "filter",
        %{"data" => filter, "page_more" => "ratings" <> _},
        socket
      ) do
    filtered = Ratings.list_ratings(Items, filter |> Plug.Conn.Query.decode())

    push(socket, "filtered_ratings", %{filter: filter, filtered: Jason.encode!(filtered)})

    {:reply, :ok, socket}
  end

  def handle_in(
        "filter",
        %{"data" => filter, "show_more" => _},
        socket
      ) do
    filtered = Comments.list_comments(Items, filter |> Plug.Conn.Query.decode())

    push(socket, "show_more_comments", %{filter: filter, filtered: Jason.encode!(filtered)})

    {:reply, :ok, socket}
  end

  def handle_in(
        "filter",
        %{"data" => filter},
        socket
      ) do
    filtered = Items.list_items(filter |> Plug.Conn.Query.decode())

    case filtered do
      [] ->
        push(socket, "error", %{
          message: "nothing to show :)"
        })

      filtered ->
        push(socket, "filtered_items", %{filter: filter, filtered: Jason.encode!(filtered)})
    end

    {:reply, :ok, socket}
  end

  def handle_in(
        "comment:add",
        %{"data" => comment},
        socket
      ) do
    case Comments.create_item_comment(
           comment
           |> Map.put("author_id", socket.assigns.current_user_id)
         ) do
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

      logged_user ->
        case Ratings.create_item_rating(rating |> Map.put("author_id", logged_user)) do
          {:ok, rating, item_rating, user_rating} ->
            broadcast!(
              socket,
              "new_rating",
              %{
                new_rating: Jason.encode!(rating)
              }
            )

            broadcast!(socket, "update_rating", %{new_rating: item_rating})

            StoreHallWeb.UsersChannel.broadcast_msg!(rating.user_id, "update_rating", %{
              new_rating: user_rating
            })

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
        %{topic: @topic_prefix <> "/" <> item_id} = socket
      ) do
    case socket.assigns.current_user_id do
      nil ->
        push(socket, "error", %{message: "must be logged in"})

      _logged_user ->
        Multi.new()
        |> Action.add_label(item_id, socket.assigns.current_user_id, reaction)
        |> Ratings.update_item_rating(item_id, [Action.reaction_to_rating(reaction)])
        |> Repo.transaction()
        |> case do
          {:ok, multi} ->
            if Map.has_key?(multi, :calc_user_rating) do
              broadcast!(socket, "update_rating", %{new_rating: multi.calc_item_rating})

              StoreHallWeb.UsersChannel.broadcast_msg!(multi.item.user_id, "update_rating", %{
                new_rating: multi.calc_user_rating
              })
            end

          {:error, _op, _value, _changes} ->
            push(socket, "error", %{
              message: "you already did it :)"
            })
        end
    end

    {:reply, :ok, socket}
  end

  def broadcast_msg!(item_id_with_slug, message, body) when is_bitstring(item_id_with_slug) do
    StoreHallWeb.Endpoint.broadcast!(@topic_prefix <> "/" <> item_id_with_slug, message, body)
  end

  def broadcast_msg(item_id_with_slug, message, body) when is_bitstring(item_id_with_slug) do
    StoreHallWeb.Endpoint.broadcast(@topic_prefix <> "/" <> item_id_with_slug, message, body)
  end
end
