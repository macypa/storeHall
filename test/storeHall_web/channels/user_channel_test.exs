defmodule StoreHallWeb.UserChannelTest do
  use StoreHallWeb.ChannelCase
  use ExUnitProperties

  alias StoreHall.Fixture
  alias StoreHallWeb.UserSocket
  alias StoreHallWeb.UsersChannel

  test "retruns filtered users", %{socket: socket} do
    push(socket, "filter", %{"data" => "[]"})

    assert_push "filtered_users", _
  end

  setup do
    user = Fixture.generate_user()

    token = Phoenix.Token.sign(@endpoint, "user token", user.id)
    {:ok, socket} = connect(UserSocket, %{"token" => token})

    {:ok, _, socket} = subscribe_and_join(socket, UsersChannel, "/users")
    {:ok, socket: socket, user: user}
  end
end
