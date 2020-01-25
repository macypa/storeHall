defmodule StoreHallWeb.AuthController do
  use StoreHallWeb, :controller
  plug Ueberauth
  import Ecto.Query, warn: false
  import Plug.Conn

  alias StoreHall.Users
  alias StoreHall.Users.User
  alias StoreHall.Repo

  def new(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    user_params = %{
      token: auth.credentials.token,
      name: auth.info.name,
      email: auth.info.email,
      image: auth.info.image,
      provider: to_string(auth.provider)
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
        |> configure_session(renew: true)
        |> put_flash(:info, Gettext.gettext("Thank you for signing in!"))
        |> put_user_props_in_session(Users.load_settings(user))
        |> redirect(to: Routes.item_path(conn, :index))

      {:error, reason} ->
        conn
        |> put_flash(:error, Gettext.gettext("Error signing in"))
        |> put_flash(:error_reason, reason)
        |> redirect(to: Routes.item_path(conn, :index))
    end
  end

  defp insert_or_update_user(user_params = %{email: email})
       when is_binary(email) and email != "" do
    case String.trim(email) do
      "" ->
        {:error, Gettext.gettext("no email")}

      email ->
        case Repo.get_by(User, email: email) do
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
            {:ok, user}
        end
    end
  end

  defp insert_or_update_user(_user_params) do
    {:error, Gettext.gettext("no email")}
  end

  def genId(info) do
    info
    |> Map.take([:name])
    |> Map.values()
    |> Enum.reject(&is_nil/1)
    |> Enum.join("")
    |> String.replace("/", "")
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
    |> redirect(to: Routes.item_path(conn, :index))
  end

  def check_owner?(conn, user_id) do
    if get_session(conn, :logged_user_id) &&
         (user_id == get_session(conn, :logged_user_id) || user_id == nil) do
      true
    else
      false
    end
  end

  def get_logged_user_id(conn) do
    get_session(conn, :logged_user_id)
  end

  def get_logged_user_image(conn) do
    get_session(conn, :logged_user_image)
  end

  def put_user_props_in_session(conn, user) do
    conn
    |> put_session(:logged_user_id, user.id)
    |> put_session(:logged_user_image, user.image)
    |> put_session(
      :logged_user_settings,
      user.settings |> Map.take(["locale", "cookie_consent", "filters"])
    )
  end
end
