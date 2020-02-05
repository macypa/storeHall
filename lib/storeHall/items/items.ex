defmodule StoreHall.Items do
  @moduledoc """
  The Items context.
  """

  import Ecto.Query, warn: false
  import PhoenixHtmlSanitizer.Helpers

  alias StoreHall.Repo
  alias StoreHall.DeepMerge
  alias Ecto.Multi

  alias StoreHall.Items.Item
  alias StoreHall.Items.Filters

  alias StoreHall.Images
  alias StoreHall.ItemFilter
  alias StoreHall.DefaultFilter
  alias StoreHall.Reactions

  @doc """
  Returns the list of items.
  """
  def list_items(params, current_user_id \\ nil) do
    apply_filters(params, current_user_id)
    |> Repo.all()
    |> Images.append_images()
  end

  defp apply_filters(params, current_user_id) do
    Item
    |> Reactions.preload_reaction(current_user_id, "item")
    |> DefaultFilter.show_with_min_rating(:user, current_user_id)
    |> DefaultFilter.show_with_max_alerts(current_user_id)
    |> DefaultFilter.sort_filter(params |> Map.put_new("filter", %{"sort" => "inserted_at:desc"}))
    |> DefaultFilter.paging_filter(params)
    |> ItemFilter.search_filter(params)
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
  def get_item_id(id) do
    {id, _} = to_string(id) |> Integer.parse()
    id
  end

  def get!(id, repo \\ Repo) do
    get_item!(id, repo)
  end

  def get_item!(id, repo \\ Repo) do
    {id, _} = to_string(id) |> Integer.parse()

    item = Item |> repo.get!(id)

    update_default_item_details(item, repo)
  end

  def get_item_with_reactions!(id, params, repo \\ Repo) do
    {id, _} = to_string(id) |> Integer.parse()

    item = Item |> Reactions.preload_reaction(params["user_id"], "item") |> repo.get!(id)

    update_default_item_details(item, repo)
  end

  def preload_user(item) do
    item
    |> Repo.preload(:user)
  end

  defp update_default_item_details(item, repo) do
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
  def create_item(item \\ %{}) do
    item = item |> init_rating

    Ecto.Multi.new()
    |> update_filter(%Filters{name: item["user_id"], type: "merchant", count: 1})
    |> update_list_filters("tags", item["details"]["tags"])
    |> update_list_filters("cities", item["details"]["cities"])
    |> Multi.insert(:insert, Item.changeset(%Item{}, prepare_for_insert(item)))
    |> Images.upsert_images(item, :insert)
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        {:ok, multi.insert}

      {:error, _op, value, _changes} ->
        {:error, value}
    end
  end

  defp prepare_for_insert(item) do
    item |> Images.prepare_images() |> prepare_price()
  end

  defp prepare_price(item) do
    price =
      item["details"]["price"]
      |> case do
        nil ->
          0

        price ->
          price
          |> Float.parse()
          |> case do
            :error -> 0
            {number, _} -> number |> Float.round(2)
          end
      end

    item |> put_in(["details", "price"], price)
  end

  defp init_rating(item) do
    # user = Users.get_user!(Map.get(item, "user_id"))
    # user.details["rating"]["score"]/user.details["items_count"]/1000 #avg user items rating
    score = 0

    item
    |> put_in(
      ["details", "rating"],
      %{"count" => 0, "score" => score}
    )
  end

  def update_filter(multi, filter, increase_by \\ 1) do
    Ecto.Multi.insert(
      multi,
      "upsert_filters" <> Map.get(filter, :name),
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

        multi_name =
          "upsert_list_filter_" <> filter_type <> to_string(filters) <> to_string(increase_by)

        multi
        |> Ecto.Multi.run(multi_name, fn repo, _ ->
          for filter <- filters do
            filter
            |> sanitize(:strip_tags)
            |> elem(1)
            |> get_parents()
            |> Enum.map(fn f ->
              repo.insert(%Filters{count: count, name: f, type: filter_type},
                on_conflict: [inc: [count: increase_by]],
                conflict_target: [:name, :type]
              )
            end)
          end

          {:ok, filters}
        end)
    end
  end

  def get_parents(path, accumulator \\ [])
  def get_parents(".", accumulator), do: accumulator

  def get_parents(path, accumulator) do
    get_parents(Path.dirname(path), [path] ++ accumulator)
  end

  defp clean_filters(multi) do
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
    |> update_list_tags(item, attrs)
    |> update_list_cities(item, attrs)
    |> Multi.update(:update, Item.changeset(item, prepare_for_insert(attrs)))
    |> Images.clean_images(item, details_to_remove(item, attrs, "images"))
    |> Images.upsert_images(attrs, :update)
    |> clean_filters()
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        {:ok, multi.update}

      {:error, _op, value, _changes} ->
        {:error, value}
    end
  end

  def update_list_tags(multi, item, attrs) do
    multi
    |> update_list_filters("tags", details_to_add(item, attrs, "tags"))
    |> update_list_filters("tags", details_to_remove(item, attrs, "tags"), -1)
  end

  def update_list_cities(multi, item, attrs) do
    multi
    |> update_list_filters("cities", details_to_add(item, attrs, "cities"))
    |> update_list_filters("cities", details_to_remove(item, attrs, "cities"), -1)
  end

  def details_to_add(item, attrs, detail_type) do
    if Map.has_key?(attrs["details"], detail_type) do
      old_details = item.details[detail_type]
      new_details = attrs["details"][detail_type]

      MapSet.difference(MapSet.new(new_details), MapSet.new(old_details))
      |> MapSet.to_list()
    end
  end

  def details_to_remove(item, attrs, detail_type) do
    if Map.has_key?(attrs["details"], detail_type) do
      old_details = item.details[detail_type]
      new_details = attrs["details"][detail_type]

      MapSet.difference(MapSet.new(old_details), MapSet.new(new_details))
      |> MapSet.to_list()
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
    |> update_list_filters("tags", item.details["tags"], -1)
    |> update_list_filters("cities", item.details["cities"], -1)
    |> Multi.delete(:delete_item, item)
    |> clean_filters()
    |> Images.clean_images(item, item.details["images"])
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        {:ok, multi.delete_item}

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

  def decode_params(item_params = %{"details" => details}) when is_binary(details) do
    item_params
    |> put_in(
      ["details"],
      Jason.decode!(details)
    )
  end

  def decode_params(item_params = %{"details" => details}) when is_map(details) do
    item_params
    |> put_in(
      ["details"],
      details
      |> decode_details_param("images")
      |> decode_details_param("videos")
      |> decode_details_param("tags")
      |> decode_details_param("cities")
      |> decode_details_param("features")
    )
  end

  def decode_params(item_params), do: item_params

  def decode_details_param(details, param) do
    case Map.has_key?(details, param) do
      true ->
        details
        |> put_in([param], Jason.decode!(details[param]))

      false ->
        details
    end
  end

  def item_filters(min_count \\ 10) do
    Filters |> Repo.all() |> Filters.to_map(min_count)
  end

  def get_feature_filters(items) do
    items
    |> Enum.reduce(%{}, fn item, acc ->
      case item.details["features"] do
        nil ->
          acc

        item_features ->
          item_features
          |> Enum.reduce(acc, fn {k, _v}, acc ->
            acc
            |> Map.put(k, k)
          end)
      end
    end)
  end

  def list_items_for_sitemap() do
    Item
    |> order_by([{:desc, :updated_at}])
    |> select([:id, :user_id, :updated_at])
    |> Repo.all()
  end
end
