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

  def join(@topic_prefix <> _id, _message, socket) do
    {:ok, socket}
  end

  def handle_in(
        "filter",
        %{"data" => filter},
        socket
      ) do
    filtered =
      Items.list_items(filter |> Plug.Conn.Query.decode())
      |> Enum.map(fn item ->
        Map.put(
          item,
          :details,
          item.details
          |> put_in(
            ["images"],
            item.details["images"]
            |> Enum.map(fn image ->
              StoreHall.Items.image_url(item, image)
            end)
          )
        )

        # Map.put(item.details, "images", StoreHall.Items.cover_image(item))
      end)

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
    case Comments.create_item_comment(comment) do
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
        case Ratings.create_item_rating(rating) do
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

  def broadcast_msg!(user_id, message, body) when is_bitstring(user_id) do
    StoreHallWeb.Endpoint.broadcast!(@topic_prefix <> user_id, message, body)
  end

  def broadcast_msg(user_id, message, body) when is_bitstring(user_id) do
    StoreHallWeb.Endpoint.broadcast(@topic_prefix <> user_id, message, body)
  end
end
