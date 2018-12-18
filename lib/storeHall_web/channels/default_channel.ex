defmodule StoreHallWeb.DefaultChannel do
  use Phoenix.Channel

  @topic_prefix "/"

  def join(@topic_prefix <> path, _message, socket) do
    {:ok, %{channel: "/#{path}"}, assign(socket, :path, path)}
  end

  def handle_in(message, content, socket) do
    path = socket.assigns[:path]
    IO.inspect("DefaultChannel #{inspect(socket)} got #{inspect(message)} : #{inspect(content)}")
    {:reply, :ok, socket}
  end
end
