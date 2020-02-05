defmodule StoreHallWeb.ItemChannelTest do
  use StoreHallWeb.ChannelCase
  use ExUnitProperties

  alias StoreHall.Fixture
  alias StoreHallWeb.UserSocket
  alias StoreHallWeb.UsersChannel
  alias StoreHallWeb.ItemsChannel

  alias StoreHall.Comments.ItemComment
  alias StoreHall.Ratings.ItemRating

  test "retruns filtered items", %{socket: socket} do
    push(socket, "filter", %{"data" => "[]"})

    assert_push "filtered_items", _
  end

  test "add comment for item", %{socket: socket, item: item, user: user, new_user: new_user} do
    comment =
      dencode(%ItemComment{item_id: item.id, user_id: new_user.id, author: user.id, reaction: nil})

    push(socket, "comment:add", %{"data" => comment})

    assert_broadcast "new_comment", %{comment_parent_id: _, new_comment: _}
  end

  describe "rating" do
    test "add when not logged", %{guest_socket: guest_socket} do
      rating = dencode(%ItemRating{author: nil, reaction: nil})
      push(guest_socket, "rating:add", %{"data" => rating})

      assert_push("error", %{message: "must be logged in"})
    end

    test "add", %{socket: socket, item: item, user: user, new_user: new_user} do
      rating =
        dencode(%ItemRating{
          item_id: item.id,
          author: user.id,
          user_id: new_user.id,
          reaction: nil
        })

      push(socket, "rating:add", %{"data" => rating})

      assert_broadcast "new_rating", %{new_rating: _}
      assert_broadcast "update_rating", %{new_rating: _}
    end

    @tag :skip
    test "error on duplicate", %{socket: socket, item: item, user: user} do
      rating = dencode(%ItemRating{item_id: item.id, author_id: user.id, user_id: user.id})
      push(socket, "rating:add", %{"data" => rating})

      refute_push("error", %{message: "you already did it :)"})

      push(socket, "rating:add", %{"data" => rating})

      assert_push("error", %{message: "you already did it :)"})
    end
  end

  setup do
    user = Fixture.generate_user()
    new_user = Fixture.generate_user()
    item = Fixture.generate_item()

    token = Phoenix.Token.sign(@endpoint, "user token", user.id)
    {:ok, socket} = connect(UserSocket, %{"token" => token})
    {:ok, _, item_socket} = subscribe_and_join(socket, ItemsChannel, "/#{item.id}")

    {:ok, guest_socket} = connect(UserSocket, %{"token" => "guest"})
    {:ok, _, guest_socket} = subscribe_and_join(guest_socket, ItemsChannel, "/#{item.id}")

    {:ok, _, _user_socket} = subscribe_and_join(socket, UsersChannel, "/users/" <> user.id)

    {:ok, _, _new_user_socket} =
      subscribe_and_join(socket, UsersChannel, "/users/" <> new_user.id)

    {:ok,
     socket: item_socket, guest_socket: guest_socket, item: item, user: user, new_user: new_user}
  end

  defp dencode(schema) do
    with {:ok, schema} = Jason.encode(schema),
         {:ok, schema} = Jason.decode(schema) do
      schema
    end
  end
end
