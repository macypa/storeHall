defmodule StoreHallWeb.UserControllerTest do
  use StoreHallWeb.ConnCase

  alias StoreHall.Repo
  alias StoreHall.Users
  alias StoreHall.Users.User

  @create_attrs %{
    id: "some_id",
    email: "some email",
    first_name: "some first_name",
    last_name: "some last_name",
    provider: "some provider",
    settings: %{labels: "{\"got\":0,\"interested\":0,\"liked\":0,\"wish\":0}"}
  }
  @update_attrs %{
    id: "some_id",
    email: "some updated email",
    first_name: "some updated first_name",
    last_name: "some updated last_name",
    provider: "some updated provider",
    settings: %{labels: "{\"got\":1,\"interested\":1,\"liked\":1,\"wish\":1}"}
  }
  @invalid_attrs %{
    email: nil,
    first_name: nil,
    last_name: nil,
    provider: nil,
    settings: %{labels: "{\"got\":1,\"interested\":1,\"liked\":1,\"wish\":1}"}
  }

  def user_fixture(attrs \\ @create_attrs) do
    {:ok, user} =
      User.changeset(%User{id: attrs.id}, attrs)
      |> Repo.insert()

    Users.get_user_with_settings!(user.id)
  end

  describe "index" do
    test "lists all users", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Users"
    end
  end

  describe "edit user" do
    setup [:create_user]

    test "editing foreign user redirects to items list", %{conn: conn, user: user} do
      conn = get(conn, Routes.user_path(conn, :edit, user))
      assert redirected_to(conn) == Routes.item_path(conn, :index)
    end

    test "renders form for editing chosen user", %{conn: conn, user: user} do
      conn = conn |> assign(:logged_user, user)
      conn = get(conn, Routes.user_path(conn, :edit, user))
      assert html_response(conn, 200) =~ "Edit User"
    end
  end

  describe "update user" do
    setup [:create_user]

    test "redirects when data is valid", %{conn: conn, user: user} do
      conn = conn |> assign(:logged_user, user)
      conn = put(conn, Routes.user_path(conn, :update, user), user: @update_attrs)
      assert redirected_to(conn) == Routes.user_path(conn, :show, user)

      conn = get(conn, Routes.user_path(conn, :show, user))
      assert html_response(conn, 200) =~ "some updated email"
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = conn |> assign(:logged_user, user)
      conn = put(conn, Routes.user_path(conn, :update, user), user: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit User"
    end
  end

  describe "delete user" do
    setup [:create_user]

    test "deletes chosen user", %{conn: conn, user: user} do
      conn = conn |> assign(:logged_user, user)
      conn = delete(conn, Routes.user_path(conn, :delete, user))
      assert redirected_to(conn) == Routes.user_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.user_path(conn, :show, user))
      end
    end
  end

  defp create_user(_) do
    user = user_fixture(@create_attrs)
    {:ok, user: user}
  end
end
