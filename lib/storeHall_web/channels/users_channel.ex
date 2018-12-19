defmodule StoreHallWeb.UsersChannel do
  use Phoenix.Channel

  import Ecto.Query, warn: false
  alias StoreHall.Repo
  alias Ecto.Multi
  alias StoreHall.Ratings
  alias StoreHall.Users
  alias StoreHall.Users.User
  alias StoreHall.Users.Relations
  alias StoreHall.Users.Action

  @topic_prefix "/users/"

  def join(@topic_prefix <> _id, _message, socket) do
    {:ok, socket}
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
end
