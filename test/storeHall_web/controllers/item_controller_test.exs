defmodule StoreHallWeb.ItemControllerTest do
  use StoreHallWeb.ConnCase
  use ExUnitProperties

  import Plug.Test

  alias StoreHall.Fixture
  alias StoreHall.Users
  alias StoreHall.Items
  alias StoreHall.Items.Item

  @item_attrs %{
    "details" => %{
      "tags" => "[]",
      "images" => "[]",
      "rating" => "{\"count\": \"0\", \"score\": \"-1\"}",
      "comments_count" => "1"
    },
    "name" => "some updated name"
  }
  @invalid_attrs %{
    "details" => %{
      "tags" => "[]",
      "images" => "[]",
      "rating" => "{\"count\": \"0\", \"score\": \"-1\"}",
      "comments_count" => "0"
    },
    "name" => ""
  }

  describe "index" do
    test "lists items", %{conn: conn} do
      conn = get(conn, Routes.item_path(conn, :index))

      assert get_flash(conn, :error) == nil
      assert html_response(conn, 200) =~ "items-listing"
    end

    @tag :skip
    test "redirected from root path", %{conn: conn} do
      conn = get(conn, "/")

      assert get_flash(conn, :error) == nil
      assert redirected_to(conn) == Routes.item_path(conn, :index)
    end
  end

  describe "show item" do
    setup [:create_user, :create_item]

    test "exists", %{conn: conn, item: item} do
      conn =
        conn
        |> init_test_session(logged_user_id: Users.get_user!(item.user_id).id)

      conn = get(conn, Routes.user_item_path(conn, :show, item.user_id, item))

      assert html_response(conn, 200) =~ item.name
      assert %Item{} = conn.assigns.item

      assert %Ecto.Association.NotLoaded{} != conn.assigns.item.comments
      assert %Ecto.Association.NotLoaded{} != conn.assigns.item.ratings
      assert %Ecto.Association.NotLoaded{} != conn.assigns.item.messages
    end

    test "does not exists", %{conn: conn, user: user} do
      assert_error_sent 404, fn ->
        get(
          conn,
          Routes.user_item_path(conn, :show, "non_existing_user", %Item{
            id: 1,
            name: @item_attrs["name"]
          })
        )

        assert_error_sent 404, fn ->
          get(
            conn,
            Routes.user_item_path(conn, :show, user.id, %Item{
              id: 1,
              name: @item_attrs["name"]
            })
          )
        end
      end
    end
  end

  describe "create item" do
    setup [:create_user]

    test "when data is valid", %{conn: conn, user: user} do
      conn =
        conn
        |> init_test_session(logged_user_id: user.id)

      conn = post(conn, Routes.user_item_path(conn, :create, user, %{"item" => @item_attrs}))

      assert get_flash(conn, :error) == nil
      assert get_flash(conn, :info) == "Item created successfully."
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn =
        conn
        |> init_test_session(logged_user_id: user.id)

      conn = post(conn, Routes.user_item_path(conn, :create, user, %{"item" => @invalid_attrs}))

      assert get_flash(conn, :error) == nil
      assert html_response(conn, 200) =~ "New Item"
      assert %Ecto.Changeset{} = conn.assigns.changeset
      assert conn.assigns.changeset.errors == [name: {"can't be blank", [validation: :required]}]
    end
  end

  describe "edit item" do
    setup [:create_user, :create_item]

    test "editing foreign item redirects to items list", %{conn: conn, user: user, item: item} do
      conn =
        conn
        |> init_test_session(logged_user_id: user.id)

      conn = get(conn, Routes.user_item_path(conn, :edit, user, item))

      assert get_flash(conn, :error) == "You cannot do that"
      assert redirected_to(conn) == Routes.item_path(conn, :index)
    end

    test "renders form for editing chosen item", %{conn: conn, item: item} do
      conn =
        conn
        |> init_test_session(logged_user_id: Users.get_user!(item.user_id).id)

      conn = get(conn, Routes.user_item_path(conn, :edit, item.user_id, item))

      assert get_flash(conn, :error) == nil
      assert html_response(conn, 200) =~ "Edit Item"

      assert %Item{} = conn.assigns.item
      assert %Ecto.Changeset{} = conn.assigns.changeset
    end

    test "restrict editing foreign item", %{conn: conn, user: user, item: item} do
      conn =
        conn
        |> init_test_session(logged_user_id: user.id)

      conn = get(conn, Routes.user_item_path(conn, :edit, user, item))

      assert get_flash(conn, :error) == "You cannot do that"
      assert redirected_to(conn) == Routes.item_path(conn, :index)
    end

    test "restrict editing items if not logged", %{conn: conn, user: user, item: item} do
      conn = get(conn, Routes.user_item_path(conn, :edit, user.id, item))

      assert get_flash(conn, :error) == "You must be logged in."
      assert redirected_to(conn) == Routes.item_path(conn, :index)
    end
  end

  describe "update item" do
    setup [:create_user, :create_item]

    test "redirects when data is valid", %{conn: conn, item: item} do
      conn =
        conn
        |> init_test_session(logged_user_id: Users.get_user!(item.user_id).id)

      conn =
        put(conn, Routes.user_item_path(conn, :update, item.user_id, item), item: @item_attrs)

      updated_item = Items.get_item!(item.id)

      assert updated_item.name == @item_attrs["name"]
      assert get_flash(conn, :error) == nil

      assert redirected_to(conn) == Routes.user_item_path(conn, :show, item.user_id, updated_item)
    end

    test "renders errors when data is invalid", %{conn: conn, item: item} do
      conn =
        conn
        |> init_test_session(logged_user_id: Users.get_user!(item.user_id).id)

      conn =
        put(conn, Routes.user_item_path(conn, :update, item.user_id, item), item: @invalid_attrs)

      assert get_flash(conn, :error) == nil
      assert html_response(conn, 200) =~ "Edit Item"
      assert %Item{} = conn.assigns.item
      assert %Ecto.Changeset{} = conn.assigns.changeset
      assert conn.assigns.changeset.errors == [name: {"can't be blank", [validation: :required]}]
    end
  end

  describe "delete item" do
    setup [:create_user, :create_item]

    test "deletes chosen item", %{conn: conn, item: item} do
      conn =
        conn
        |> init_test_session(logged_user_id: Users.get_user!(item.user_id).id)

      conn = delete(conn, Routes.user_item_path(conn, :delete, item.user_id, item))
      assert redirected_to(conn) == Routes.item_path(conn, :index)
      assert get_flash(conn, :info) == "Item deleted successfully."

      assert_error_sent 404, fn ->
        get(conn, Routes.user_item_path(conn, :show, item.user_id, item))
      end
    end

    test "restrict deleting foreign item", %{conn: conn, user: user, item: item} do
      conn =
        conn
        |> init_test_session(logged_user_id: user.id)

      conn = delete(conn, Routes.user_item_path(conn, :delete, item.user_id, item))

      assert get_flash(conn, :error) == "You cannot do that"
      assert redirected_to(conn) == Routes.item_path(conn, :index)

      conn = get(conn, Routes.user_item_path(conn, :show, item.user_id, item))
      assert html_response(conn, 200) =~ item.name
    end

    test "restrict deleting items if not logged", %{conn: conn, item: item} do
      conn = delete(conn, Routes.user_item_path(conn, :delete, item.user_id, item))

      assert get_flash(conn, :error) == "You must be logged in."
      assert redirected_to(conn) == Routes.item_path(conn, :index)

      conn = get(conn, Routes.user_item_path(conn, :show, item.user_id, item))
      assert html_response(conn, 200) =~ item.name
    end
  end

  defp create_user(_) do
    user = Users.get_user_with_settings!(Fixture.generate_user().id)
    {:ok, user: user}
  end

  defp create_item(_) do
    item = Items.get_item!(Fixture.generate_item().id)
    {:ok, item: item}
  end
end
