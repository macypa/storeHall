defmodule StoreHall.ParseNumbers do
  def prepare_number(item, map_key) do
    item
    |> get_in(map_key)
    |> case do
      nil ->
        item

      number ->
        item |> put_in(map_key, parse_number(number))
    end
  end

  def parse_number(nil), do: 0
  def parse_number(int) when is_integer(int), do: int
  def parse_number(float) when is_float(float), do: float |> Float.round(2)

  def parse_number(str) when is_binary(str) do
    str
    |> Float.parse()
    |> case do
      :error ->
        str
        |> Integer.parse()
        |> case do
          :error -> 0
          {number, _} -> number
        end

      {number, _} ->
        parse_number(number)
    end
  end
end
