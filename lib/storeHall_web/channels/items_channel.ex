defmodule StoreHallWeb.ItemsChannel do
  use Phoenix.Channel

  require StoreHallWeb.Gettext
  alias StoreHallWeb.Gettext, as: Gettext

  import Ecto.Query, warn: false
  alias StoreHall.Ratings
  alias StoreHall.Comments
  alias StoreHall.Items

  @topic_prefix "/items"

  def topic_prefix() do
    @topic_prefix
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
        Items,
        socket.assigns.current_user_id,
        filter |> Plug.Conn.Query.decode()
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
        Items,
        socket.assigns.current_user_id,
        filter |> Plug.Conn.Query.decode()
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
        Items,
        socket.assigns.current_user_id,
        filter |> Plug.Conn.Query.decode()
      )

    push(socket, "show_for_comment", %{
      filter: filter,
      filtered: Jason.encode!(filtered)
    })

    {:reply, :ok, socket}
  end

  def handle_in(
        "filter",
        %{"data" => filter, "show_for" => "rating" <> _},
        socket
      ) do
    filtered =
      Ratings.list_ratings(
        Items,
        socket.assigns.current_user_id,
        filter |> Plug.Conn.Query.decode()
      )

    push(socket, "show_for_rating", %{
      filter: filter,
      filtered: Jason.encode!(filtered)
    })

    {:reply, :ok, socket}
  end

  def handle_in(
        "filter",
        %{"data" => filter},
        socket
      ) do
    filtered = Items.list_items(filter |> Plug.Conn.Query.decode())

    push(socket, "filtered_items", %{filter: filter, filtered: Jason.encode!(filtered)})

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
        case Comments.create_item_comment(comment |> Map.put("author_id", logged_user_id)) do
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
              case Ratings.create_item_rating(rating |> Map.put("author_id", logged_user_id)) do
                {:ok, rating} ->
                  broadcast!(
                    socket,
                    "new_rating",
                    %{
                      rating_parent_id: rating.rating_id,
                      new_rating: Jason.encode!(rating)
                    }
                  )

                {:ok, rating, item_rating, user_rating} ->
                  broadcast!(
                    socket,
                    "new_rating",
                    %{
                      rating_parent_id: rating.rating_id,
                      new_rating: Jason.encode!(rating)
                    }
                  )

                  StoreHallWeb.UsersChannel.broadcast_updated_rating_item(
                    Items.get_item!(rating.item_id),
                    item_rating
                  )

                  StoreHallWeb.UsersChannel.broadcast_updated_rating_user(
                    rating.user_id,
                    user_rating
                  )

                {:error, _rating} ->
                  push(socket, "error", %{
                    message: Gettext.gettext("you already did it :)")
                  })
              end
          end
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
