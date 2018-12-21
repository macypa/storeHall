defmodule StoreHallWeb.UsersChannel do
  use Phoenix.Channel

  import Ecto.Query, warn: false
  alias StoreHall.Repo
  alias Ecto.Multi
  alias StoreHall.Ratings
  alias StoreHall.Comments
  alias StoreHall.Users.Action

  @topic_prefix "/users/"

  def join(@topic_prefix <> _id, _message, socket) do
    {:ok, socket}
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
            new_comment:
              Phoenix.View.render_to_string(
                StoreHallWeb.CommentView,
                "show.html",
                %{
                  comment: comment,
                  comments_info: %{
                    comment: %{
                      author_id: socket.assigns.current_user_id,
                      user_id: comment.user_id
                    }
                  }
                }
              )
          }
        )
    end

    {:reply, :ok, socket}
  end

  def handle_in(
        "reaction:" <> reaction,
        %{"data" => _data},
        %{topic: @topic_prefix <> user_id} = socket
      ) do
    Multi.new()
    |> Action.add_relation(user_id, socket.assigns.current_user_id, reaction)
    |> Ratings.update_user_rating(user_id, [Action.reaction_to_rating(reaction)])
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        broadcast!(socket, "update_rating", %{new_rating: multi.calc_user_rating})
        {:reply, :ok, socket}

      {:error, _op, _value, _changes} ->
        push(socket, "error", %{message: "must be logged in to do that, or you already did it :)"})

        {:reply, :ok, socket}
    end
  end

  def broadcast_msg!(user_id, message, body) when is_bitstring(user_id) do
    StoreHallWeb.Endpoint.broadcast!(@topic_prefix <> user_id, message, body)
  end

  def broadcast_msg(user_id, message, body) when is_bitstring(user_id) do
    StoreHallWeb.Endpoint.broadcast(@topic_prefix <> user_id, message, body)
  end
end
