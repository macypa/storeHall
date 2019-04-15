defmodule StoreHall.ItemsTest do
  use StoreHall.DataCase
  use ExUnitProperties

  alias StoreHall.Fixture
  alias StoreHall.Items

  @items_count 100

  describe "items" do
    alias StoreHall.Items.Item
    alias StoreHall.Users.User

    @user_attrs %{
      id: "some_id",
      email: "some email",
      image: "",
      first_name: "some first_name",
      last_name: "some last_name",
      provider: "some provider"
    }
    @valid_attrs %{
      "details" => %{
        "tags" => [],
        "images" => [],
        "rating" => %{"count" => 0, "score" => -1},
        "comments_count" => 0
      },
      "name" => "some name",
      "user_id" => "some_id"
    }
    @update_attrs %{
      "details" => %{
        "tags" => [],
        "images" => [],
        "rating" => %{"count" => 0, "score" => -1},
        "comments_count" => 1
      },
      "name" => "some updated name",
      "user_id" => "some_id"
    }
    @invalid_attrs %{
      "details" => %{
        "tags" => [],
        "images" => [],
        "rating" => %{"count" => 0, "score" => -1},
        "comments_count" => 0
      },
      "name" => "",
      "user_id" => "some_invalid_id"
    }

    def user_fixture(attrs \\ @user_attrs) do
      {:ok, user} =
        User.changeset(%User{id: attrs.id}, attrs)
        |> Repo.insert()

      user
    end

    def item_fixture(attrs \\ @valid_attrs) do
      user_fixture()

      {:ok, item} =
        attrs
        |> Items.create_item()

      item
    end

    test "list_items/0 returns all items" do
      items = Fixture.insert_items(@items_count)
      assert length(Repo.all(Item)) == length(items)
    end

    test "get_item!/1 returns the item with given id" do
      item = item_fixture()
      assert Items.get_item!(item.id) == item
    end

    test "create_item/1 with valid data creates a item" do
      assert {:ok, %Item{} = item} = Items.create_item(@valid_attrs)

      assert item.details == %{
               "tags" => [],
               "images" => [],
               "rating" => %{"count" => 0, "score" => -1},
               "comments_count" => 0
             }

      assert item.name == "some name"
      assert item.user_id == "some_id"
    end

    test "create_item/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Items.create_item(@invalid_attrs)
    end

    test "update_item/2 with valid data updates the item" do
      item = item_fixture()
      assert {:ok, %Item{} = item} = Items.update_item(item, @update_attrs)

      assert item.details == %{
               "tags" => [],
               "images" => [],
               "rating" => %{"count" => 0, "score" => -1},
               "comments_count" => 1
             }

      assert item.name == "some updated name"
      assert item.user_id == "some_id"
    end

    test "update_item/2 with invalid data returns error changeset" do
      item = item_fixture()
      assert {:error, %Ecto.Changeset{}} = Items.update_item(item, @invalid_attrs)
      assert item == Items.get_item!(item.id)
    end

    test "delete_item/1 deletes the item" do
      item = item_fixture()
      assert {:ok, %Item{}} = Items.delete_item(item)
      assert_raise Ecto.NoResultsError, fn -> Items.get_item!(item.id) end
    end

    test "change_item/1 returns a item changeset" do
      item = item_fixture()
      assert %Ecto.Changeset{} = Items.change_item(item)
    end
  end
end
