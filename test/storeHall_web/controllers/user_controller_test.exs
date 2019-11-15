defmodule StoreHallWeb.UserControllerTest do
  use StoreHallWeb.ConnCase
  use ExUnitProperties

  alias StoreHall.Fixture
  alias StoreHall.Users
  alias StoreHall.Users.User

  @user_attrs %{
    id: "some_id",
    email: "some updated email",
    first_name: "some updated first_name",
    last_name: "some updated last_name",
    provider: "some updated provider",
    settings: %{
      labels: "{\"got\":1,\"interested\":1,\"liked\":1,\"wish\":1}",
      filters: "{\"show_with_min_rating\":-1, \"hide_guests\":false}"
    }
  }
  @invalid_attrs %{
    email: nil,
    first_name: nil,
    last_name: nil,
    provider: nil,
    settings: %{
      labels: "{\"got\":1,\"interested\":1,\"liked\":1,\"wish\":1}",
      filters: "{\"show_with_min_rating\":-1, \"hide_guests\":false}"
    }
  }

  describe "index" do
    test "lists users", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :index))

      assert get_flash(conn, :error) == nil
      assert html_response(conn, 200) =~ "Listing users"
      assert conn.assigns.users != nil
    end
  end

  describe "show user" do
    setup [:create_user]

    test "exists", %{conn: conn, user: user} do
      conn = conn |> assign(:logged_user, user)
      conn = get(conn, Routes.user_path(conn, :show, user))

      assert html_response(conn, 200) =~ "Show User"
      assert %User{} = conn.assigns.user

      assert %Ecto.Association.NotLoaded{} != conn.assigns.user.comments
      assert %Ecto.Association.NotLoaded{} != conn.assigns.user.ratings
      assert %Ecto.Association.NotLoaded{} != conn.assigns.user.messages
    end

    test "does not exists", %{conn: conn} do
      assert_error_sent 404, fn ->
        get(
          conn,
          Routes.user_path(conn, :show, %User{
            id: "non-existing-user",
            first_name: @user_attrs["first_name"],
            email: @user_attrs["email"]
          })
        )
      end
    end
  end

  describe "edit user" do
    setup [:create_user]

    test "restricts editing user if not logged", %{conn: conn, user: user} do
      conn = get(conn, Routes.user_path(conn, :edit, user))

      assert get_flash(conn, :error) == "You must be logged in."
      assert redirected_to(conn) == Routes.item_path(conn, :index)
    end

    test "editing foreign user redirects to items list", %{conn: conn, user: user} do
      conn = conn |> assign(:logged_user, Fixture.generate_user())
      conn = get(conn, Routes.user_path(conn, :edit, user))

      assert get_flash(conn, :error) == "You cannot do that"
      assert redirected_to(conn) == Routes.user_path(conn, :index)
    end

    test "renders form for editing chosen user", %{conn: conn, user: user} do
      conn = conn |> assign(:logged_user, user)
      conn = get(conn, Routes.user_path(conn, :edit, user))

      assert get_flash(conn, :error) == nil
      assert html_response(conn, 200) =~ "Edit User"
      assert %User{} = conn.assigns.user
      assert %Ecto.Changeset{} = conn.assigns.changeset
    end

    test "restrict editing other user", %{conn: conn, user: user} do
      conn = conn |> assign(:logged_user, user)
      conn = get(conn, Routes.user_path(conn, :edit, Fixture.generate_user()))

      assert get_flash(conn, :error) == "You cannot do that"
      assert redirected_to(conn) == Routes.user_path(conn, :index)
    end
  end

  describe "update user" do
    setup [:create_user]

    test "redirects when data is valid", %{conn: conn, user: user} do
      conn = conn |> assign(:logged_user, user)
      conn = put(conn, Routes.user_path(conn, :update, user), user: @user_attrs)

      assert get_flash(conn, :error) == nil
      assert redirected_to(conn) == Routes.user_path(conn, :show, user)

      conn = get(conn, Routes.user_path(conn, :show, user))
      assert html_response(conn, 200) =~ "some updated email"
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = conn |> assign(:logged_user, user)
      conn = put(conn, Routes.user_path(conn, :update, user), user: @invalid_attrs)

      assert get_flash(conn, :error) == nil
      assert html_response(conn, 200) =~ "Edit User"
    end
  end

  describe "delete user" do
    setup [:create_user]

    test "deletes chosen user", %{conn: conn, user: user} do
      conn = conn |> assign(:logged_user, user)
      conn = delete(conn, Routes.user_path(conn, :delete, user))

      assert get_flash(conn, :error) == nil
      assert redirected_to(conn) == Routes.user_path(conn, :index)
      assert get_flash(conn, :info) == "User deleted successfully."

      assert_error_sent 404, fn ->
        get(conn, Routes.user_path(conn, :show, user))
      end
    end

    test "restrict deleting other user", %{conn: conn, user: user} do
      conn = conn |> assign(:logged_user, user)
      conn = delete(conn, Routes.user_path(conn, :delete, Fixture.generate_user()))

      assert get_flash(conn, :error) == "You cannot do that"
      assert redirected_to(conn) == Routes.user_path(conn, :index)

      conn = get(conn, Routes.user_path(conn, :show, user))
      assert html_response(conn, 200) =~ "Show User"
    end
  end

  defp create_user(_) do
    user = Users.get_user_with_settings!(Fixture.generate_user().id)
    {:ok, user: user}
  end
end
