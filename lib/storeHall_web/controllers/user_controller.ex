defmodule StoreHallWeb.UserController do
  use StoreHallWeb, :controller
  use Rummage.Phoenix.Controller

  alias StoreHall.Users
  alias StoreHall.Users.User

  plug :check_owner when action in [:edit, :delete]

  def index(conn, params) do
    {users, rummage} = Users.list_users(params)
    render(conn, :index, users: users, rummage: rummage)
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
    user = Users.get_user!(id)
    render(conn, :show, user: user)
  end

  def edit(conn, %{"id" => id}) do
    user = Users.get_user!(id)
    changeset = Users.change_user(user)
    render(conn, :edit, user: user, changeset: changeset)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Users.get_user!(id)

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
    user = Users.get_user!(id)
    {:ok, _user} = Users.delete_user(user)

    conn
    |> put_flash(:info, "User deleted successfully.")
    |> redirect(to: Routes.user_path(conn, :index))
  end

  defp check_owner(conn, _params) do
    %{params: %{"id" => user_id}} = conn

    if conn.assigns && conn.assigns.user && user_id === conn.assigns.user.id do
      conn
    else
      conn
      |> put_flash(:error, "You cannot do that")
      |> redirect(to: Routes.user_path(conn, :index))
      |> halt()
    end
  end
end
