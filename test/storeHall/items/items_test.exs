defmodule StoreHall.ItemsTest do
  use StoreHall.DataCase
  use ExUnitProperties

  alias StoreHall.Fixture
  alias StoreHall.Items
  alias StoreHall.Items.Item

  @items_count 100

  describe "items" do
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

    test "list_items/0 returns all items" do
      items = Fixture.insert_items(@items_count)
      assert length(Repo.all(Item)) == length(items)
    end

    test "get_item!/1 returns the item with given id" do
      items = Fixture.insert_items(@items_count)

      check all item <- StreamData.member_of(items) do
        assert Items.get_item!(item.id) == item
      end
    end

    test "create_item/1 with valid data creates a item" do
      assert {:ok, %Item{} = item} =
               Items.create_item(%{
                 "name" => "some name",
                 "user_id" => "some_id"
               })

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
      item = Fixture.generate_item()
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
      item = Fixture.generate_item()
      assert {:error, %Ecto.Changeset{}} = Items.update_item(item, @invalid_attrs)
      assert item == Items.get_item!(item.id)
    end

    test "delete_item/1 deletes the item" do
      check all item <- Fixture.item_generator() do
        assert {:ok, %Item{}} = Items.delete_item(item)
        assert_raise Ecto.NoResultsError, fn -> Items.get_item!(item.id) end
      end
    end

    test "change_item/1 returns a item changeset" do
      items = Fixture.insert_items(@items_count)

      check all item <- StreamData.member_of(items) do
        assert %Ecto.Changeset{} = Items.change_item(item)
      end
    end
  end
end
