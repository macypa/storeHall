defmodule StoreHallWeb.AuthControllerTest do
  use StoreHallWeb.ConnCase
  use ExUnitProperties

  import Plug.Test

  alias StoreHall.Fixture
  alias StoreHallWeb.AuthController

  test "redirects user to Google for authentication", %{conn: conn} do
    conn = get(conn, "/auth/google")
    assert redirected_to(conn, 302)
  end

  test "creates user from Google information", %{conn: conn} do
    # ueberauth_auth = Fixture.generate_ueberauth()
    check all(ueberauth_auth <- Fixture.ueberauth_generator()) do
      conn =
        conn
        |> assign(:ueberauth_auth, ueberauth_auth)
        |> get("/auth/google/callback")

      case conn.private.plug_session["phoenix_flash"]["error_reason"] do
        nil ->
          assert get_flash(conn, :error) == nil
          assert AuthController.get_logged_user_id(conn) != ""
          assert get_flash(conn, :info) == "Thank you for signing in!"

        reason ->
          assert reason == nil
      end
    end
  end

  test "shows a sign out link when signed in", %{conn: conn} do
    user = Fixture.generate_user()

    conn =
      conn
      |> init_test_session(cu_id: user.id)
      |> get("/users")

    assert get_flash(conn, :error) == nil
    assert html_response(conn, 200) =~ "Sign out"
  end

  test "signs out user", %{conn: conn} do
    user = Fixture.generate_user()

    conn =
      conn
      |> init_test_session(cu_id: user.id)
      |> get("/auth/delete")
      |> get("/")

    assert get_flash(conn, :error) == nil
    assert AuthController.get_logged_user_id(conn) == nil
  end
end
