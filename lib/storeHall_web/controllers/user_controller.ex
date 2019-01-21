defmodule StoreHallWeb.UserController do
  use StoreHallWeb, :controller

  alias StoreHallWeb.AuthController
  alias StoreHall.Users
  alias StoreHall.Users.User
  alias StoreHall.Comments
  alias StoreHall.Ratings

  plug :check_owner when action in [:edit, :delete]

  def index(conn, params) do
    users = Users.list_users(params)
    render(conn, :index, users: users)
  end

  def new(conn, _params) do
    changeset = Users.change_user(%User{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Users.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: Routes.user_path(conn, :show, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    user = get_user!(conn, id)

    render(conn, :show,
      user: user,
      comments_info: collect_comments_info(conn, user),
      ratings_info: collect_ratings_info(conn, user)
    )
  end

  def collect_comments_info(conn, user) do
    %{
      comments: Comments.for_user(user.id),
      comment: %{
        author_id: AuthController.get_user_id_from_conn(conn),
        user_id: user.id
      }
    }
  end

  def collect_ratings_info(conn, user) do
    %{
      ratings: Ratings.for_user(user.id),
      rating: %{
        author_id: AuthController.get_user_id_from_conn(conn),
        user_id: user.id,
        scores: %{}
      }
    }
  end

  def edit(conn, %{"id" => id}) do
    user = get_user!(conn, id)
    changeset = Users.change_user(user)
    render(conn, :edit, user: user, changeset: changeset)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = get_user!(conn, id)

    user_params =
      user_params
      |> put_in(
        ["settings", "labels"],
        Poison.decode!(get_in(user_params, ["settings", "labels"]))
      )

    case Users.update_user(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: Routes.user_path(conn, :show, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, user: user, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = get_user!(conn, id)
    {:ok, _user} = Users.delete_user(user)

    conn
    |> put_flash(:info, "User deleted successfully.")
    |> redirect(to: Routes.user_path(conn, :index))
  end

  defp check_owner(conn, _params) do
    %{params: %{"id" => user_id}} = conn

    if AuthController.check_owner?(conn, user_id) do
      conn
    else
      conn
      |> put_flash(:error, "You cannot do that")
      |> redirect(to: Routes.user_path(conn, :index))
      |> halt()
    end
  end

  defp get_user!(conn, id) do
    if AuthController.check_owner?(conn, id) do
      Users.get_user_with_settings!(id)
    else
      Users.get_user!(id)
    end
  end
end
