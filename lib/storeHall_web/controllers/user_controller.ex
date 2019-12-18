defmodule StoreHallWeb.UserController do
  use StoreHallWeb, :controller

  alias StoreHallWeb.AuthController
  alias StoreHall.Users
  alias StoreHall.Chats
  alias StoreHall.Users.User
  alias StoreHall.Ratings
  alias StoreHall.Comments
  alias StoreHall.Images

  plug :check_owner when action in [:edit, :delete]

  def index(conn, _params) do
    users = [
      %User{
        id: "{{id}}",
        image: "{{image}}",
        first_name: "{{first_name}}",
        last_name: "{{last_name}}",
        inserted_at: "{{inserted_at}}",
        updated_at: "{{updated_at}}",
        details: %{
          "user_template_tag_id" => "user_template",
          "images" => ["{{#each details.images}}<div data-img='{{this}}'> </div>{{/each}}"],
          "rating" => %{"score" => "{{json details.rating.score}}"},
          "comments_count" => "{{json details.comments_count}}"
        }
      }
      | Users.list_users(conn.params)
    ]

    render(conn, :index, users: users)
  end

  def show(conn, params = %{"id" => id}) do
    user =
      get_user!(conn, id)
      |> Images.append_images(:image)
      |> Comments.preload_for(AuthController.get_user_id_from_conn(conn), params)
      |> Ratings.preload_for(AuthController.get_user_id_from_conn(conn), params)
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

    case Users.update_user(user, Users.decode_params(user_params)) do
      {:ok, user} ->
        conn
        |> put_flash(:info, Gettext.gettext("User updated successfully."))
        |> redirect(to: Routes.user_path(conn, :show, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, user: user, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = get_user!(conn, id)

    case Users.delete_user(user) do
      {:ok} ->
        conn
        |> put_flash(:info, Gettext.gettext("User deleted successfully."))
        |> redirect(to: Routes.auth_path(conn, :delete))

      {:error} ->
        conn
        |> put_flash(:error, Gettext.gettext("User not deleted."))
        |> redirect(to: Routes.user_path(conn, :show, user))
    end
  end

  defp check_owner(conn, _params) do
    %{params: %{"id" => user_id}} = conn

    if AuthController.check_owner?(conn, user_id) do
      conn
    else
      conn
      |> put_flash(:error, Gettext.gettext("You cannot do that"))
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
