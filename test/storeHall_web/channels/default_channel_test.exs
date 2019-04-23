defmodule StoreHallWeb.DefaultChannelTest do
  use StoreHallWeb.ChannelCase
  use ExUnitProperties

  alias StoreHall.Fixture
  alias StoreHallWeb.UserSocket
  alias StoreHallWeb.DefaultChannel

  test "assigns path to the socket after join",
       %{socket: socket, path: path} do
    assert socket.assigns.path == "#{path}"
  end

  test "every message replies with status ok", %{socket: socket} do
    ref = push(socket, "random_msg", %{"inspect" => false})
    assert_reply ref, :ok
  end

  setup do
    user = Fixture.generate_user()

    token = Phoenix.Token.sign(@endpoint, "user token", user.id)
    {:ok, socket} = connect(UserSocket, %{"token" => token})

    {:ok, _, socket} = subscribe_and_join(socket, DefaultChannel, "/default")
    {:ok, socket: socket, user: user, path: "default"}
  end
end
