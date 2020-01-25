defmodule StoreHallWeb.UserSocketTest do
  use StoreHallWeb.ChannelCase, async: true
  alias StoreHallWeb.UserSocket

  test "authenticate with valid token" do
    token = Phoenix.Token.sign(@endpoint, "user token", "user-id")

    assert {:ok, socket} = connect(UserSocket, %{"token" => token})
    assert socket.assigns.current_user_id == "user-id"
  end

  test "authenticate with guest", %{socket: socket} do
    assert socket.assigns.current_user_id == nil
  end

  test "authenticate with invalid token" do
    assert :error = connect(UserSocket, %{"token" => "invalid-token"})
    assert :error = connect(UserSocket, %{})
  end

  test "connect to default channel", %{socket: socket} do
    {:ok, _, socket} = subscribe_and_join(socket, "/default")
    assert socket.channel == StoreHallWeb.DefaultChannel

    {:ok, _, socket} = subscribe_and_join(socket, "/dsfhjghdfk")
    assert socket.channel == StoreHallWeb.DefaultChannel
  end

  test "connect to users channel", %{socket: socket} do
    {:ok, _, socket} = subscribe_and_join(socket, "/users")
    assert socket.channel == StoreHallWeb.UsersChannel

    {:ok, _, socket} = subscribe_and_join(socket, "/users/some_user")
    assert socket.channel == StoreHallWeb.UsersChannel
  end

  test "connect to items channel", %{socket: socket} do
    {:ok, _, socket} = subscribe_and_join(socket, "/")
    assert socket.channel == StoreHallWeb.ItemsChannel

    {:ok, _, socket} = subscribe_and_join(socket, "/some_item")
    assert socket.channel == StoreHallWeb.ItemsChannel
  end

  setup do
    {:ok, socket} = connect(UserSocket, %{"token" => "guest"})

    {:ok, socket: socket}
  end
end
