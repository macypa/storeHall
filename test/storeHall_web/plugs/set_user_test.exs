defmodule StoreHallWeb.SetUserTest do
  use StoreHallWeb.ConnCase
  use ExUnitProperties

  alias StoreHall.Fixture
  alias StoreHallWeb.AuthController

  test "assign nil as user, guest as token", %{conn: conn} do
    conn = get(conn, Routes.user_path(conn, :index))

    case conn.private.plug_session["cu_id"] do
      nil ->
        assert AuthController.get_logged_user_id(conn) == nil
        assert conn.assigns.user_token == "guest"

      _ ->
        assert false
    end
  end

  test "assign user and token from session", %{conn: conn} do
    user = Fixture.generate_user()

    conn =
      conn
      |> Plug.Test.init_test_session(%{logged_user_id: user.id})

    conn =
      conn
      |> get(Routes.user_path(conn, :index))

    assert AuthController.get_logged_user_id(conn) == user.id

    {:ok, user_id} =
      Phoenix.Token.verify(conn, "user token", conn.assigns.user_token, max_age: 60)

    assert user_id == user.id
  end
end
