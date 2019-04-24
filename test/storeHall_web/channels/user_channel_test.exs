defmodule StoreHallWeb.UserChannelTest do
  use StoreHallWeb.ChannelCase
  use ExUnitProperties

  alias StoreHall.Fixture
  alias StoreHallWeb.UserSocket
  alias StoreHallWeb.UsersChannel

  alias StoreHall.Comments.UserComment
  alias StoreHall.Ratings.UserRating

  test "retruns filtered users", %{socket: socket} do
    push(socket, "filter", %{"data" => "[]"})

    assert_push "filtered_users", _
  end

  test "add comment for user", %{socket: socket, user: user} do
    comment = dencode(%UserComment{user_id: user.id})
    push(socket, "comment:add", %{"data" => comment})

    assert_broadcast "new_comment", %{comment_parent_id: _, new_comment: _}
  end

  describe "rating" do
    test "add when not logged", %{guest_socket: guest_socket} do
      rating = dencode(%UserRating{})
      push(guest_socket, "rating:add", %{"data" => rating})

      assert_push("error", %{message: "must be logged in"})
    end

    test "add", %{socket: socket, user: user} do
      rating = dencode(%UserRating{user_id: user.id, author_id: user.id})
      push(socket, "rating:add", %{"data" => rating})

      assert_broadcast "new_rating", %{new_rating: _}
      assert_broadcast "update_rating", %{new_rating: _}
    end

    test "error on duplicate", %{socket: socket, user: user} do
      rating = dencode(%UserRating{user_id: user.id, author_id: user.id})
      push(socket, "rating:add", %{"data" => rating})

      refute_push("error", %{message: "you already did it :)"})

      push(socket, "rating:add", %{"data" => rating})

      assert_push("error", %{message: "you already did it :)"})
    end
  end

  describe "reaction" do
    test "add when not logged", %{guest_socket: guest_socket} do
      push(guest_socket, "reaction:wow", %{"data" => nil})

      assert_push("error", %{message: "must be logged in"})
    end

    test "wow", %{socket: socket} do
      push(socket, "reaction:wow", %{"data" => nil})

      assert_broadcast "update_rating", %{new_rating: _}
    end

    test "lol", %{socket: socket} do
      push(socket, "reaction:lol", %{"data" => nil})

      assert_broadcast "update_rating", %{new_rating: _}
    end

    test "error on wierd reaction", %{socket: socket} do
      push(socket, "reaction:NORlolNORwow", %{"data" => nil})

      refute_broadcast "update_rating", %{new_rating: _}
    end

    test "lol and wow on same user", %{socket: socket} do
      push(socket, "reaction:lol", %{"data" => nil})

      assert_broadcast "update_rating", %{new_rating: _}
      push(socket, "reaction:wow", %{"data" => nil})

      assert_broadcast "update_rating", %{new_rating: _}
    end

    test "error on duplicate", %{socket: socket} do
      push(socket, "reaction:wow", %{"data" => nil})

      refute_push("error", %{message: "you already did it :)"})

      push(socket, "reaction:wow", %{"data" => nil})

      assert_push("error", %{message: "you already did it :)"})
    end
  end

  setup do
    user = Fixture.generate_user()

    token = Phoenix.Token.sign(@endpoint, "user token", user.id)
    {:ok, socket} = connect(UserSocket, %{"token" => token})

    {:ok, _, socket} = subscribe_and_join(socket, UsersChannel, "/users/" <> user.id)

    {:ok, guest_socket} = connect(UserSocket, %{"token" => "guest"})
    {:ok, _, guest_socket} = subscribe_and_join(guest_socket, UsersChannel, "/users/" <> user.id)

    {:ok, socket: socket, guest_socket: guest_socket, user: user}
  end

  defp dencode(schema) do
    with {:ok, schema} = Jason.encode(schema),
         {:ok, schema} = Jason.decode(schema) do
      schema
    end
  end
end
