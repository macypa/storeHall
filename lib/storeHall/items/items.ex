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
    |> update_filter(%Filters{name: attrs["user_id"], type: "merchant", count: 1})
    |> update_tags(attrs["details"]["tags"])
    |> Multi.insert(:insert, Item.changeset(%Item{}, attrs))
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        {:ok, multi.insert}
    end
  end

  def update_filter(multi, filter, increase_by \\ 1) do
    Ecto.Multi.insert(
      multi,
      "upsert_Filters" <> Map.get(filter, :name),
      filter,
      on_conflict: [inc: [count: increase_by]],
      conflict_target: [:name, :type]
    )
  end

  def update_tags(multi, tags, increase_by \\ 1) do
    count = if increase_by > 0, do: 1, else: 0

    multi
    |> Ecto.Multi.run("insert_tag_filter" <> to_string(tags), fn repo, _ ->
      for t <- tags do
        repo.insert(%Filters{count: count, name: t, type: "tag"},
          on_conflict: [inc: [count: increase_by]],
          conflict_target: [:name, :type]
        )
      end

      {:ok, "tags"}
    end)
  end

  def clean_filters(multi) do
    queryable = from(f in Filters, where: f.count < 1)
    multi |> Multi.delete_all(:delete_empty, queryable)
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
    old_tags = item.details["tags"]
    new_tags = attrs["details"]["tags"]

    remove_tags = MapSet.difference(MapSet.new(old_tags), MapSet.new(new_tags))
    add_tags = MapSet.difference(MapSet.new(new_tags), MapSet.new(old_tags))

    Ecto.Multi.new()
    |> update_tags(MapSet.to_list(add_tags))
    |> update_tags(MapSet.to_list(remove_tags), -1)
    |> Multi.update(:update, item |> Item.changeset(attrs))
    |> clean_filters()
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        {:ok, multi.update}
    end
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
    Ecto.Multi.new()
    |> update_filter(
      %Filters{name: item.user_id, type: "merchant", count: 0},
      -1
    )
    |> update_tags(item.details["tags"], -1)
    |> Multi.delete(:delete, item)
    |> clean_filters()
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        {:ok, multi.delete}
    end
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
