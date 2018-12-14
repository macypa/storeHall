defmodule StoreHall.DeepMerge do
  def merge(left, nil), do: left
  def merge(left, right), do: Map.merge(left, right, &deep_resolve/3)
  defp deep_resolve(_key, left = %{}, right = %{}), do: merge(left, right)
  defp deep_resolve(_key, left, nil), do: left
  defp deep_resolve(_key, _left, right), do: right
end
