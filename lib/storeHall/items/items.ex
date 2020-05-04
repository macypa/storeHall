defmodule StoreHall.Items do
  @moduledoc """
  The Items context.
  """

  import Ecto.Query, warn: false
  import PhoenixHtmlSanitizer.Helpers

  alias StoreHall.Repo
  alias Ecto.Multi

  alias StoreHall.Items.Item
  alias StoreHall.Items.Filters

  alias StoreHall.Images
  alias StoreHall.Users
  alias StoreHall.ItemFilter
  alias StoreHall.DefaultFilter
  alias StoreHall.Reactions

  @doc """
  Returns the list of items.
  """
  def list_items(params, current_user_id \\ nil) do
    apply_filters(params, current_user_id)
    |> Repo.all()
    |> Users.preload_users(Repo)
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

    Item |> repo.get!(id)
  end

  def get_item_with_reactions!(id, params, repo \\ Repo) do
    {id, _} = to_string(id) |> Integer.parse()

    Item |> Reactions.preload_reaction(params["user_id"], "item") |> repo.get!(id)
  end

  def preload_user(item) do
    item
    |> Users.preload_users(Repo)
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
    item
    |> Images.prepare_images()
    |> prepare_number(["details", "price"])
    |> prepare_number(["details", "price_orig"])
    |> prepare_number(["details", "discount"])
  end

  defp prepare_number(item, map_key) do
    number =
      item
      |> get_in(map_key)
      |> case do
        nil ->
          0

        number ->
          number
          |> parse_number()
      end

    item |> put_in(map_key, number)
  end

  defp parse_number(int) when is_integer(int), do: int
  defp parse_number(float) when is_float(float), do: float |> Float.round(2)

  defp parse_number(str) when is_binary(str) do
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

  def item_template() do
    %Item{
      id: "{{id}}",
      name: "{{name}}",
      user: %{:name => "{{user.name}}"},
      user_id: "{{user_id}}",
      inserted_at: "{{inserted_at}}",
      updated_at: "{{updated_at}}",
      alertz_count: "{{alertz_count}}",
      lolz_count: "{{lolz_count}}",
      wowz_count: "{{wowz_count}}",
      mehz_count: "{{mehz_count}}",
      reaction: %{
        reaction: "{{reaction.reaction}}"
      },
      details: %{
        "price" => "{{json details.price}}",
        "price_orig" => "{{json details.price_orig}}",
        "discount" => "{{json details.discount}}",
        "images" => ["{{#each details.images}}<div data-img='{{this}}'> </div>{{/each}}"],
        "rating" => %{
          "score" => "{{json details.rating.score}}",
          "count" => "{{json details.rating.count}}"
        },
        "comments_count" => "{{json details.comments_count}}"
      }
    }
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

  def item_filters(min_count \\ 0) do
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
          |> Enum.reduce(acc, fn entry, acc ->
            acc |> put_feature_filter(entry)
          end)
      end
    end)
  end

  defp put_feature_filter(acc, entry) do
    split_entry = String.split(entry, ":", trim: true)

    key = split_entry |> hd

    acc
    |> Map.put(key, key)
  end

  def list_items_for_sitemap() do
    Item
    |> order_by([{:desc, :updated_at}])
    |> select([:id, :user_id, :updated_at])
    |> Repo.all()
  end
end
