defmodule StoreHall.Items do
  @moduledoc """
  The Items context.
  """

  import Ecto.Query, warn: false
  alias StoreHall.Repo
  alias Ecto.Multi

  alias StoreHall.Items.Item
  alias StoreHall.Items.Filters

  @doc """
  Returns the list of items.

  ## Examples

      iex> list_items()
      [%Item{}, ...]

  """
  def list_items do
    Repo.all(Item)
  end

  @doc """
  Gets a single item.

  Raises `Ecto.NoResultsError` if the Item does not exist.

  ## Examples

      iex> get_item!(123)
      %Item{}

      iex> get_item!(456)
      ** (Ecto.NoResultsError)

  """
  def get_item!(id), do: Repo.get!(Item, id)

  @doc """
  Creates a item.

  ## Examples

      iex> create_item(%{field: value})
      {:ok, %Item{}}

      iex> create_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_item(attrs \\ %{}) do
    "attrs: #{inspect(attrs)}"

    Ecto.Multi.new()
    |> Multi.append(update_filters(attrs))
    |> Multi.insert(:insert, Item.changeset(%Item{}, attrs))
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        {:ok, multi.insert}
    end
  end

  def update_filters(attrs \\ %{}) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :insert_merchant_filter,
      %Filters{count: 1, name: attrs["user_id"], type: "merchant"},
      on_conflict: [inc: [count: 1]],
      conflict_target: [:name, :type]
    )
    |> Ecto.Multi.run(:insert_tag_filter, fn repo, _ ->
      for t <- attrs["details"]["tags"] do
        repo.insert(%Filters{count: 1, name: t, type: "tag"},
          on_conflict: [inc: [count: 1]],
          conflict_target: [:name, :type]
        )
      end

      {:ok, "tags"}
    end)
  end

  @doc """
  Updates a item.

  ## Examples

      iex> update_item(item, %{field: new_value})
      {:ok, %Item{}}

      iex> update_item(item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_item(%Item{} = item, attrs) do
    item
    |> Item.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Item.

  ## Examples

      iex> delete_item(item)
      {:ok, %Item{}}

      iex> delete_item(item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_item(%Item{} = item) do
    Repo.delete(item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking item changes.

  ## Examples

      iex> change_item(item)
      %Ecto.Changeset{source: %Item{}}

  """
  def change_item(%Item{} = item) do
    Item.changeset(item, %{})
  end
end
