defmodule StoreHall.EncodeHelper do
  def encode(%{__struct__: _} = struct) do
    struct
    |> Map.from_struct()
    |> encode()
  end

  def encode(list) when is_list(list) do
    Enum.map(list, fn x -> encode(x) end)
  end

  def encode(%{} = map) do
    map =
      Enum.into(map, %{}, fn
        {key, %Ecto.Association.NotLoaded{}} -> {key, nil}
        {key, value} -> {key, value}
      end)

    {:ok, encoded} =
      map
      |> Map.drop([:__meta__, :__struct__])
      |> Jason.encode()

    encoded
  end

  def encode!(%{__struct__: _} = struct) do
    struct
    |> Map.from_struct()
    |> encode!()
  end

  def encode!(list) when is_list(list) do
    Enum.map(list, fn x -> encode!(x) end)
  end

  def encode!(%{} = map) do
    map
    |> Map.drop([:__meta__, :__struct__])
    |> Enum.into(%{}, fn
      {key, %Ecto.Association.NotLoaded{}} -> {key, nil}
      {key, value} -> {key, value}
    end)
    |> Jason.encode!()
  end
end

defimpl Jason.Encoder, for: Ecto.Association.NotLoaded do
  def encode(struct, opts) do
    "{}"
  end
end

defimpl Phoenix.HTML.Safe, for: Map do
  def to_iodata(data), do: data |> Jason.encode!() |> Plug.HTML.html_escape()
end
