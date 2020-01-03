defmodule StoreHallWeb.SetUserTest do
  use StoreHallWeb.ConnCase
  use ExUnitProperties

  alias StoreHall.Fixture

  test "assign nil as user, guest as token", %{conn: conn} do
    conn = get(conn, Routes.user_path(conn, :index))

    case conn.private.plug_session["logged_user_id"] do
      nil ->
        assert conn.assigns.logged_user_id == nil
        assert conn.assigns.user_token == "guest"

      _ ->
        assert false
    end
  end

  test "assign user and token from session", %{conn: conn} do
    user = Fixture.generate_user()

    conn =
      conn
      |> Plug.Test.init_test_session(%{logged_user_id: user})

    conn =
      conn
      |> get(Routes.user_path(conn, :index))

    assert conn.assigns.logged_user_id == user

    {:ok, user_id} =
      Phoenix.Token.verify(conn, "user token", conn.assigns.user_token, max_age: 60)

    assert user_id == user.id
  end
end
