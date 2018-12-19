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
    |> Ratings.update_user_rating(user_id, [reaction_to_rating(reaction)])
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

  def reaction_to_rating(reaction) when reaction in ["wow"], do: 5
  def reaction_to_rating(reaction) when reaction in ["lol"], do: 0
  def reaction_to_rating(_reaction), do: nil

  def update_user_labels() do
    # query =
    #   from f in Settings,
    #     where: f.id == ^id,
    #     update: [
    #       set: [
    #         settings:
    #           fragment(
    #             " jsonb_set(settings, '{labels, liked}', (COALESCE(settings->'labels'->>'liked','0')::int + 1)::text::jsonb) "
    #           )
    #       ]
    #     ]
    #
    # Repo.update_all(query, [])
  end
end
