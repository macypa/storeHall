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
      "name" => ""
    }

    test "list_items/0 returns all items" do
      items = Fixture.insert_items(@items_count)
      assert length(Repo.all(Item)) == length(items)
    end

    test "get_item!/1 returns the item with given id" do
      check all item <- Fixture.item_generator() do
        assert Items.get_item!(item.id) == item
      end
    end

    test "get_item!/1 merges default details" do
      item = Fixture.generate_item()

      Items.update_item(item, %{
        "details" => %{
          "tags" => [],
          "images" => [],
          "rating" => %{"score" => -1},
          "comments_count" => 1
        }
      })

      assert Items.get_item!(item.id).details["rating"] == %{"count" => 0, "score" => -1}
      assert Items.get_item!(item.id).details["comments_count"] == 1
    end

    test "create_item/1 with valid data creates an item" do
      user = Fixture.generate_user()

      check all item_attrs <- Fixture.item_generator(user, &Fixture.item_generator_fun_do_none/2) do
        item_attrs
        |> Items.create_item()
        |> case do
          {:error, _changeset} ->
            nil

          {:ok, item} ->
            assert %Item{} = item

            assert item.details == %{
                     "tags" => item_attrs["details"]["tags"],
                     "images" => item_attrs["details"]["images"],
                     "rating" => %{
                       "count" => 0,
                       "score" => user.details["rating"]["score"]
                     },
                     "comments_count" => item_attrs["details"]["comments_count"]
                   }

            assert item.name == item_attrs["name"]
            assert item.user_id == item_attrs["user_id"]
        end
      end
    end

    test "create_item/1 with invalid data returns error changeset" do
      item_attr =
        ExUnitProperties.pick(Fixture.item_generator(nil, &Fixture.item_generator_fun_do_none/2))
        |> Map.put("name", "")

      assert {:error, %Ecto.Changeset{}} = Items.create_item(item_attr)
    end

    test "create_item/1 updates item filters table" do
      user = Fixture.generate_user()

      check all item_attrs <- Fixture.item_generator(user, &Fixture.item_generator_fun_do_none/2) do
        filters_before = Items.item_filters()

        item_attrs
        |> Items.create_item()
        |> case do
          {:error, _changeset} ->
            nil

          {:ok, item} ->
            tags =
              Enum.reduce(item.details["tags"], filters_before["tags"], fn tag, acc ->
                Map.put(
                  acc,
                  tag,
                  case Map.get(acc, tag) do
                    nil -> 1
                    count -> count + 1
                  end
                )
              end)

            case item_attrs do
              [] -> assert Items.item_filters()["tags"] != filters_before["tags"]
              _ -> assert Items.item_filters()["tags"] == tags
            end
        end
      end
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

    test "delete_item/1 updates item filters table" do
      user = Fixture.generate_user()
      # Fixture.insert_items(@items_count)
      Fixture.insert_items(5)

      check all item_attrs <- Fixture.item_generator(user, &Fixture.item_generator_fun_do_none/2) do
        item_attrs
        |> Items.create_item()
        |> case do
          {:error, _changeset} ->
            nil

          {:ok, item} ->
            filters_before = Items.item_filters()

            assert {:ok, %Item{}} = Items.delete_item(item)

            tags =
              Enum.reduce(item.details["tags"], filters_before["tags"], fn tag, acc ->
                case Map.get(acc, tag) do
                  nil ->
                    acc

                  count ->
                    case count do
                      1 ->
                        Map.delete(acc, tag)

                      count ->
                        Map.put(
                          acc,
                          tag,
                          count - 1
                        )
                    end
                end
              end)

            case item_attrs do
              [] -> assert Items.item_filters()["tags"] != filters_before["tags"]
              _ -> assert Items.item_filters()["tags"] == tags
            end
        end
      end
    end

    test "change_item/1 returns a item changeset" do
      check all item <- Fixture.item_generator() do
        assert %Ecto.Changeset{} = Items.change_item(item)
      end
    end
  end
end
