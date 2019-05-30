defmodule StoreHallWeb.DefaultChannel do
  use Phoenix.Channel

  @topic_prefix "/"

  def topic_prefix() do
    @topic_prefix
  end

  def join(@topic_prefix <> path, _message, socket) do
    {:ok, %{channel: "/#{path}"}, assign(socket, :path, path)}
  end

  def handle_in(message, content, socket) do
    path = socket.assigns[:path]

    case content["inspect"] do
      false ->
        {:reply, :ok, socket}

      _ ->
        IO.inspect(
          "DefaultChannel #{inspect(socket)} got #{inspect(message)} : #{inspect(content)} : #{
            path
          }"
        )

        {:reply, :ok, socket}
    end
  end
end
