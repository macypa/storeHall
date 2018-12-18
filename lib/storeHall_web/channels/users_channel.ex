defmodule StoreHallWeb.UsersChannel do
  use Phoenix.Channel

  @topic_prefix "/users/"

  def join(@topic_prefix <> _id, _message, socket) do
    {:ok, socket}
  end

  def handle_in(
        "reaction:" <> raction,
        %{"data" => data},
        %{topic: @topic_prefix <> user_id} = socket
      ) do
    {:reply, :ok, socket}
  end
end
