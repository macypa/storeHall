defmodule StoreHallWeb.AuthControllerTest do
  use StoreHallWeb.ConnCase
  use ExUnitProperties

  alias StoreHall.Fixture

  test "redirects user to Google for authentication", %{conn: conn} do
    conn = get(conn, "/auth/google")
    assert redirected_to(conn, 302)
  end

  test "creates user from Google information", %{conn: conn} do
    # ueberauth_auth = Fixture.generate_ueberauth()
    check all ueberauth_auth <- Fixture.ueberauth_generator() do
      conn =
        conn
        |> assign(:ueberauth_auth, ueberauth_auth)
        |> get("/auth/google/callback")

      assert conn.private.plug_session["logged_user"].id != ""
      assert conn.private.plug_session["logged_user"].inserted_at != ""
      assert get_flash(conn, :info) == "Thank you for signing in!"
    end
  end

  test "shows a sign out link when signed in", %{conn: conn} do
    user = Fixture.generate_user()

    conn =
      conn
      |> assign(:logged_user, user)
      |> get("/users")

    assert html_response(conn, 200) =~ "Sign out"
  end

  test "signs out user", %{conn: conn} do
    user = Fixture.generate_user()

    conn =
      conn
      |> assign(:logged_user, user)
      |> get("/auth/delete")
      |> get("/")

    assert conn.assigns.logged_user == nil
  end
end
