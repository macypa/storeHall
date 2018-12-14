defmodule StoreHall.Items do
  @moduledoc """
  The Items context.
  """

  import Ecto.Query, warn: false
  alias StoreHall.Repo
  alias StoreHall.DeepMerge
  alias Ecto.Multi

  alias StoreHall.Items
  alias StoreHall.Items.Item
  alias StoreHall.Items.Filters

  @doc """
  Returns the list of items.

  ## Examples

      iex> list_items()
      [%Item{}, ...]

  """
  def list_items(params) do
    # Repo.all(Item)
    {items, rummage} =
      Item
      |> Rummage.Ecto.rummage(params["rummage"])

    items =
      items
      |> Repo.all()

    {items, rummage}
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
  def get_item!(id, repo \\ Repo) do
    item = repo.get!(Item, id)
    update_default_item_details(item, repo)
  end

  defp update_default_item_details(item, repo \\ Repo) do
    details =
      %Item{}.details
      |> DeepMerge.merge(item.details)

    item
    |> Item.changeset(%{details: details})
    |> repo.update()
    |> case do
      {:ok, updated_item} -> updated_item
      {:error, _error} -> item
    end
  end

  @doc """
  Creates a item.

  ## Examples

      iex> create_item(%{field: value})
      {:ok, %Item{}}

      iex> create_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_item(attrs \\ %{}) do
    Ecto.Multi.new()
    |> update_filter(%Filters{name: attrs["user_id"], type: "merchant", count: 1})
    |> update_list_filters("tags", attrs["details"]["tags"])
    |> Multi.insert(:insert, Item.changeset(%Item{}, attrs))
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        {:ok, multi.insert}

      {:error, _op, value, _changes} ->
        {:error, value}
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

  def update_list_filters(multi, filter_type, filters, increase_by \\ 1) do
    case filters do
      nil ->
        multi

      filters ->
        count = if increase_by > 0, do: 1, else: 0
        multi_name = "upsert_list_filter_" <> filter_type <> to_string(filters)

        multi
        |> Ecto.Multi.run(multi_name, fn repo, _ ->
          for filter <- filters do
            filter
            |> get_parents
            |> Enum.map(fn f ->
              repo.insert(%Filters{count: count, name: f, type: filter_type},
                on_conflict: [inc: [count: increase_by]],
                conflict_target: [:name, :type]
              )
            end)
          end
        end)
    end
  end

  def get_parents(path, accumulator \\ [])
  def get_parents(".", accumulator), do: accumulator

  def get_parents(path, accumulator) do
    get_parents(Path.dirname(path), [path] ++ accumulator)
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
    Ecto.Multi.new()
    |> update_list_filters("tags", filters_to_add(item, attrs, "tags"))
    |> update_list_filters("tags", filters_to_remove(item, attrs, "tags"), -1)
    |> Multi.update(:update, item |> Item.changeset(attrs))
    |> clean_filters()
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        {:ok, multi.update}

      {:error, _op, value, _changes} ->
        {:error, value}
    end
  end

  def filters_to_add(item, attrs, filter_type) do
    old_filters = item.details[filter_type]
    new_filters = attrs["details"][filter_type]

    MapSet.difference(MapSet.new(new_filters), MapSet.new(old_filters))
    |> MapSet.to_list()
  end

  def filters_to_remove(item, attrs, filter_type) do
    old_filters = item.details[filter_type]
    new_filters = attrs["details"][filter_type]

    MapSet.difference(MapSet.new(old_filters), MapSet.new(new_filters))
    |> MapSet.to_list()
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
    |> update_list_filters("tags", item.details["tags"], -1)
    |> Multi.delete(:delete, item)
    |> clean_filters()
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        {:ok, multi.delete}

      {:error, _op, value, _changes} ->
        {:error, value}
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

  def item_filters() do
    Filters |> Repo.all() |> Filters.to_map()
  end
end
