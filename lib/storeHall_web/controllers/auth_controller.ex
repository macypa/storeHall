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
      provider: "google"
    }

    changeset = User.changeset(%User{id: genId(user_params)}, user_params)

    create(conn, changeset)
  end

  def create(conn, changeset) do
    case insert_or_update_user(changeset) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Thank you for signing in!")
        |> put_session(:user, Users.load_settings(user))
        |> redirect(to: StoreHallWeb.Router.Helpers.item_path(conn, :index))

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Error signing in")
        |> redirect(to: StoreHallWeb.Router.Helpers.item_path(conn, :index))
    end
  end

  defp insert_or_update_user(changeset) do
    case Repo.get_by(User, email: changeset.changes.email) do
      nil ->
        try do
          changeset
          |> Repo.insert()
        rescue
          _ ->
            User.changeset(%User{id: genNextId(changeset.changes)}, changeset.changes)
            |> Repo.insert()
        end

      user ->
        {:ok, user}
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
end
