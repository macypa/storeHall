defmodule StoreHall.EncodeHelper do
  def decode(params, key) do
    Map.drop(params, [key])
    |> Map.put(key, Jason.decode!(params[key]))
  end
end

defimpl Phoenix.HTML.Safe, for: Map do
  def to_iodata(data), do: data |> Jason.encode!() |> Plug.HTML.html_escape()
end
