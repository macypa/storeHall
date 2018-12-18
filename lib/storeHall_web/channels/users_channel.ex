defmodule StoreHallWeb.UsersChannel do
  use Phoenix.Channel

  import Ecto.Query, warn: false
  alias StoreHall.Repo
  alias Ecto.Multi
  alias StoreHall.Ratings
  alias StoreHall.Users
  alias StoreHall.Users.User
  alias StoreHall.Users.Relations

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
    |> add_relation(user_id, socket.assigns.current_user_id, reaction)
    |> update_user_rating(user_id, reaction_to_rating(reaction))
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
  def reaction_to_rating(_reaction), do: -1

  def update_user_rating(multi, user_id, rating \\ 5)
  def update_user_rating(multi, _user_id, -1), do: multi

  def update_user_rating(multi, user_id, rating) do
    multi
    |> Multi.run(:user, fn repo, %{} ->
      {:ok, Users.get_user!(user_id, repo)}
    end)
    |> Multi.run(:calc_user_rating, fn repo, %{user: user} ->
      Ratings.calculate_rating_score([rating], repo, User, user)
    end)
  end

  def add_relation(multi, user_id, current_user_id, reaction \\ 5)
  def add_relation(multi, _user_id, _current_user_id, -1), do: multi

  def add_relation(multi, user_id, current_user_id, reaction) do
    multi
    |> Multi.insert(
      :insert,
      Relations.changeset(%Relations{}, %{
        user_id: user_id,
        related_to_user_id: current_user_id,
        type: reaction
      })
    )
  end

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
