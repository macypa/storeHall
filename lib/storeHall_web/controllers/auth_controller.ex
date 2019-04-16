defmodule StoreHallWeb.AuthController do
  use StoreHallWeb, :controller
  plug Ueberauth
  import Ecto.Query, warn: false
  alias StoreHall.Users
  alias StoreHall.Users.User
  alias StoreHall.Repo

  def new(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    user_params = %{
      token: auth.credentials.token,
      first_name: auth.info.first_name,
      last_name: auth.info.last_name,
      email: auth.info.email,
      image: auth.info.image,
      provider: "google"
    }

    create(conn, user_params)
  end

  defp changeset(gen_id_fun, user_params) do
    User.changeset(%User{id: gen_id_fun.(user_params)}, user_params)
  end

  def create(conn, user_params) do
    case insert_or_update_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Thank you for signing in!")
        |> put_session(:logged_user, Users.load_settings(user))
        |> redirect(to: StoreHallWeb.Router.Helpers.item_path(conn, :index))

      {:error, reason} ->
        conn
        |> put_flash(:error, "Error signing in")
        |> put_flash(:error_reason, reason)
        |> redirect(to: StoreHallWeb.Router.Helpers.item_path(conn, :index))
    end
  end

  defp insert_or_update_user(user_params) do
    case Repo.get_by(User, email: user_params.email) do
      nil ->
        try do
          changeset(&genId/1, user_params)
          |> Repo.insert()
        rescue
          _ ->
            changeset(&genNextId/1, user_params)
            |> Repo.insert()
        end

      user ->
        Users.update_user(user, user_params)
    end
  end

  def genId(info) do
    info
    |> Map.take([:first_name, :last_name])
    |> Map.values()
    |> Enum.reject(&is_nil/1)
    |> Enum.join(".")
  end

  def genNextId(info) do
    id = genId(info)

    user_count =
      User
      |> where([u], like(u.id, ^"#{id}%"))
      |> select([u], count(u.id))
      |> Repo.one()

    case user_count do
      nil -> id
      user_count -> id <> to_string(user_count + 1)
    end
  end

  def delete(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: StoreHallWeb.Router.Helpers.item_path(conn, :index))
  end

  def check_owner?(conn, user_id) do
    if conn.assigns && conn.assigns.logged_user &&
         (user_id == conn.assigns.logged_user.id || user_id == nil) do
      true
    else
      false
    end
  end

  def get_user_id_from_conn(conn) do
    if conn.assigns && conn.assigns.logged_user && conn.assigns.logged_user.id do
      conn.assigns.logged_user.id
    else
      -1
    end
  end
end
