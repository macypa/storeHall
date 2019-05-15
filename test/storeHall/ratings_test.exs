defmodule StoreHall.RatingsTest do
  use StoreHall.DataCase
  use ExUnitProperties

  alias StoreHall.Fixture
  alias StoreHall.Items
  alias StoreHall.Users
  alias StoreHall.Ratings

  describe "item ratings" do
    test "for_item/1 returns all ratings" do
      user = Fixture.generate_user()
      item = Fixture.generate_item(user)

      check all author <- Fixture.user_generator() do
        item_ratings_count = length(Ratings.for_item(item.id))

        Ratings.create_item_rating(%{
          "item_id" => item.id,
          "user_id" => item.user_id,
          "author_id" => author.id,
          "details" => %{"scores" => %{"clean" => "3"}}
        })

        assert length(Ratings.for_item(item.id)) == item_ratings_count + 1
      end
    end

    test "create_rating/1 updates rating count for item and user" do
      user = Fixture.generate_user()
      item = Fixture.generate_item(user)

      check all author <- Fixture.user_generator() do
        item_ratings_count = Items.get_item!(item.id).details["rating"]["count"]
        user_ratings_count = Users.get_user!(item.user_id).details["rating"]["count"]

        Ratings.create_item_rating(%{
          "item_id" => item.id,
          "user_id" => item.user_id,
          "author_id" => author.id,
          "details" => %{"scores" => %{"clean" => "3"}}
        })

        assert Items.get_item!(item.id).details["rating"]["count"] == item_ratings_count + 1
        assert Users.get_user!(item.user_id).details["rating"]["count"] == user_ratings_count + 1
      end
    end

    test "create_rating/1 updates rating score between 0 and 5" do
      user = Fixture.generate_user()
      item = Fixture.generate_item(user)

      check all author <- Fixture.user_generator(),
                score <- StreamData.integer(0..5) do
        Ratings.create_item_rating(%{
          "item_id" => item.id,
          "user_id" => item.user_id,
          "author_id" => author.id,
          "details" => %{"scores" => %{"clean" => score}}
        })

        assert Items.get_item!(item.id).details["rating"]["score"] >= 0
        assert Items.get_item!(item.id).details["rating"]["score"] <= 5
        assert Users.get_user!(item.user_id).details["rating"]["score"] >= 0
        assert Users.get_user!(item.user_id).details["rating"]["score"] <= 5
      end
    end
  end
end
