defmodule StoreHall.CommentsTest do
  use StoreHall.DataCase
  use ExUnitProperties

  alias StoreHall.Fixture
  alias StoreHall.Items
  alias StoreHall.Users
  alias StoreHall.Comments
  alias StoreHall.Comments.ItemComment
  alias StoreHall.Comments.UserComment

  describe "item comments" do
    test "list_comments returns all comments" do
      author = Fixture.generate_user()

      check all item <- Fixture.item_generator(),
                comments_count <- StreamData.positive_integer() do
        item_comments = Fixture.insert_item_comments(author, item, nil, nil, comments_count)

        assert length(
                 Comments.list_comments(Items, author.id, %{
                   "id" => item.id,
                   "page-size" => "1111"
                 })
               ) == length(item_comments)
      end
    end

    test "create_comment/1 updates comment count for item" do
      author = Fixture.generate_user()

      check all item <- Fixture.item_generator() do
        item_comments_count = Items.get_item!(item.id).details["comments_count"]
        user_comments_count = Users.get_user!(item.user_id).details["comments_count"]

        assert {:ok, %ItemComment{} = comment} =
                 Comments.create_item_comment(%{
                   "item_id" => item.id,
                   "author_id" => author.id,
                   "user_id" => item.user_id,
                   "details" => %{"body" => "body"}
                 })

        assert comment.details == %{
                 "body" => "body"
               }

        assert comment.id > 0
        assert Items.get_item!(item.id).details["comments_count"] == item_comments_count + 1
        assert Users.get_user!(item.user_id).details["comments_count"] == user_comments_count + 1
      end
    end
  end

  describe "user comments" do
    test "list_comments returns all comments" do
      author = Fixture.generate_user()

      check all user <- Fixture.user_generator(),
                comments_count <- StreamData.positive_integer() do
        user_comments = Fixture.insert_user_comments(author, user, nil, comments_count)

        assert length(
                 Comments.list_comments(Users, author.id, %{
                   "id" => user.id,
                   "page-size" => "1111"
                 })
               ) == length(user_comments)
      end
    end

    test "create_comment/1 updates comment count for user" do
      author = Fixture.generate_user()

      check all user <- Fixture.user_generator() do
        user_comments_count = Users.get_user!(user.id).details["comments_count"]

        assert {:ok, %UserComment{} = comment} =
                 Comments.create_user_comment(%{
                   "user_id" => user.id,
                   "author_id" => author.id,
                   "details" => %{"body" => "body"}
                 })

        assert comment.details == %{
                 "body" => "body"
               }

        assert comment.id > 0
        assert Users.get_user!(user.id).details["comments_count"] == user_comments_count + 1
      end
    end
  end
end
