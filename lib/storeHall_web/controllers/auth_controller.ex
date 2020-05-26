defmodule StoreHallWeb.AuthController do
  use StoreHallWeb, :controller
  plug Ueberauth

  alias StoreHall.Repo
  import Ecto.Query, warn: false
  import Plug.Conn

  alias StoreHall.Users
  alias StoreHall.Users.User
  alias StoreHall.Marketing.Mails
  alias StoreHallWeb.CookieConsentController

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
    case insert_or_update_user(conn, user_params) do
      {:ok, user} ->
        spawn(fn ->
          :timer.sleep(5000)
          Mails.broadcast_first_unread_mails(user.id)
        end)

        conn
        |> clear_session()
        |> configure_session(renew: true)
        |> CookieConsentController.update_cookie_consent_to_agreed(user.id)
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

  defp insert_or_update_user(conn, user_params = %{email: email})
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
            |> elem(1)
            |> Users.update_user(%{
              "marketing_info" => get_session(conn, :cu_market_info) || %{}
            })

          user ->
            case get_session(conn, :cu_market_info)["marketing_consent"] == "agreed" do
              true ->
                user
                |> Users.update_user(%{"marketing_info" => %{"marketing_consent" => "agreed"}})

              false ->
                {:ok, user}
            end
        end
    end
  end

  defp insert_or_update_user(_conn, _user_params) do
    {:error, Gettext.gettext("no email")}
  end

  def genId(info) do
    info
    |> Map.take([:name])
    |> Map.values()
    |> Enum.reject(&is_nil/1)
    |> Enum.join("")
    |> String.replace(" ", "")
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
    if get_session(conn, :cu_id) &&
         (user_id == get_session(conn, :cu_id) || user_id == nil) do
      true
    else
      false
    end
  end

  def get_logged_user_id(conn) do
    get_session(conn, :cu_id)
  end

  def get_logged_user_image(conn) do
    get_session(conn, :cu_image)
  end

  def update_user_props_in_session(conn) do
    case get_session(conn, :cu_id) do
      nil ->
        conn

      user_id ->
        conn
        |> put_user_props_in_session(Users.get_user_with_settings!(user_id))
    end
  end

  def put_user_props_in_session(conn, user) do
    conn
    |> put_session(:cu_id, user.id)
    |> put_session(:cu_image, Users.get_user_image(user))
    |> put_session(:cu_settings, user.settings)
    |> put_session(
      :cu_market_info,
      user.marketing_info |> Map.take(["marketing_consent", "last_activity"])
    )
  end
end
