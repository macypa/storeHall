defmodule StoreHallWeb.AuthControllerTest do
  use StoreHallWeb.ConnCase
  ## Add this line
  alias StoreHall.Repo
  alias StoreHall.Users
  alias StoreHall.Users.User

  ## Add this
  @ueberauth_auth %{
    credentials: %{token: "fdsnoafhnoofh08h38h"},
    info: %{email: "ironman@example.com", first_name: "Tony", last_name: "Stark", image: ""},
    provider: :google
  }
  @valid_user_attrs %{
    id: "some_id",
    email: "some email",
    image: "",
    first_name: "some first_name",
    last_name: "some last_name",
    provider: "some provider"
  }

  def user_fixture(attrs \\ @valid_user_attrs) do
    {:ok, user} =
      User.changeset(%User{id: attrs.id}, attrs)
      |> Repo.insert()

    user
  end

  test "redirects user to Google for authentication", %{conn: conn} do
    conn = get(conn, "/auth/google")
    assert redirected_to(conn, 302)
  end

  test "creates user from Google information", %{conn: conn} do
    conn =
      conn
      |> assign(:ueberauth_auth, @ueberauth_auth)
      |> get("/auth/google/callback")

    user_id = @ueberauth_auth.info.first_name <> "." <> @ueberauth_auth.info.last_name
    user = Users.get_user!(user_id)

    assert user.id == user_id
    assert get_flash(conn, :info) == "Thank you for signing in!"
  end

  test "shows a sign out link when signed in", %{conn: conn} do
    user = user_fixture()

    conn =
      conn
      |> assign(:logged_user, user)
      |> get("/users")

    assert html_response(conn, 200) =~ "Sign out"
  end

  test "signs out user", %{conn: conn} do
    user = user_fixture()

    conn =
      conn
      |> assign(:logged_user, user)
      |> get("/auth/delete")
      |> get("/")

    assert conn.assigns.logged_user == nil
  end
end
