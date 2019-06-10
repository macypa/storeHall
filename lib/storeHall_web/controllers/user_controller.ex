defmodule StoreHallWeb.UserController do
  use StoreHallWeb, :controller

  alias StoreHallWeb.AuthController
  alias StoreHall.Users
  alias StoreHall.Chats
  alias StoreHall.Ratings
  alias StoreHall.Comments

  plug :check_owner when action in [:edit, :delete]

  def index(conn, _params) do
    users = Users.list_users(conn.params)

    render(conn, :index, users: users)
  end

  def show(conn, params = %{"id" => id}) do
    user =
      get_user!(conn, id)
      |> Comments.preload_for(params)
      |> Ratings.preload_for(params)
      |> Chats.preload_for(AuthController.get_user_id_from_conn(conn))

    render(conn, :show, user: user)
  end

  def edit(conn, %{"id" => id}) do
    user = get_user!(conn, id)
    changeset = Users.change_user(user)
    render(conn, :edit, user: user, changeset: changeset)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = get_user!(conn, id)

    case Users.update_user(user, Users.decode_user_params(user_params)) do
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
    {:ok} = Users.delete_user(user)

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
