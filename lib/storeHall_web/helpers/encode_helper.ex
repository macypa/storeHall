defmodule StoreHall.EncodeHelper do
  def decode(nil), do: nil
  def decode(""), do: nil

  def decode(string) when is_binary(string) do
    case Jason.decode(string) do
      {:ok, decoded} -> decoded
      _error -> string
    end
  end

  def decode(%{__struct__: _} = struct) do
    struct
    |> Map.from_struct()
    |> decode()
  end

  def decode(list) when is_list(list) do
    Enum.map(list, fn value -> decode(value) end)
  end

  def decode(map) when is_map(map) do
    map |> Map.new(fn {key, value} -> {key, decode(value)} end)
  end

  def decode(value), do: value

  # def encode(%{__struct__: _} = struct) do
  #   struct
  #   |> Map.from_struct()
  #   |> encode()
  # end

  # def encode(list) when is_list(list) do
  #   Enum.map(list, fn x -> encode(x) end)
  # end

  # def encode(%{} = map) do
  #   map =
  #     map
  #     |> Map.drop([:__meta__, :__struct__])
  #     |> Enum.map(fn key_val ->
  #       case key_val do
  #         {key, %Ecto.Association.NotLoaded{}} -> {key, nil}
  #         {key, value} -> {key, value}
  #       end
  #     end)

  #   {:ok, encoded} = map |> Jason.encode()

  #   encoded
  # end

  # def encode!(%{__struct__: _} = struct) do
  #   struct
  #   |> Map.from_struct()
  #   |> encode!()
  # end

  # def encode!(list) when is_list(list) do
  #   Enum.map(list, fn x -> encode!(x) end)
  # end

  # def encode!(%{} = map) do
  #   map
  #   |> Map.drop([:__meta__, :__struct__])
  #   |> Enum.into(%{}, fn
  #     {key, %Ecto.Association.NotLoaded{}} -> {key, nil}
  #     {key, value} -> {key, value}
  #   end)
  #   |> Jason.encode!()
  # end
end

defimpl Phoenix.HTML.Safe, for: Map do
  def to_iodata(data), do: data |> Jason.encode!() |> Plug.HTML.html_escape()
end
