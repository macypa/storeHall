defmodule StoreHall.Items do
  @moduledoc """
  The Items context.
  """

  import Ecto.Query, warn: false
  alias StoreHall.Repo
  alias StoreHall.DeepMerge
  alias Ecto.Multi

  alias StoreHall.Users
  alias StoreHall.Items.Item
  alias StoreHall.Items.Filters

  alias StoreHall.FileUploader
  alias StoreHall.ItemFilter
  alias StoreHall.DefaultFilter
  alias StoreHall.Reactions

  @doc """
  Returns the list of items.

  ## Examples

      iex> list_items()
      [%Item{}, ...]

  """
  def list_items(params \\ nil) do
    apply_filters(params)
    |> Repo.all()
    |> Enum.map(fn item ->
      Map.put(
        item,
        :details,
        item.details
        |> put_in(
          ["images"],
          item.details["images"]
          |> Enum.map(fn image ->
            StoreHall.Items.image_url(item, image)
          end)
        )
      )
    end)
  end

  defp apply_filters(params) do
    Item
    |> Reactions.preload_reaction(params["user_id"], "item")
    |> DefaultFilter.sort_filter(params |> Map.put_new("filter", %{"sort" => "inserted_at:desc"}))
    |> DefaultFilter.paging_filter(params)
    |> ItemFilter.search_filter(params)
  end

  @cover_image_not_found nil

  def cover_image(item) do
    case item.details["images"] do
      nil -> @cover_image_not_found
      "[]" -> @cover_image_not_found
      "null" -> @cover_image_not_found
      [] -> @cover_image_not_found
      images -> Enum.at(images, 0)
    end
  end

  def image_url(item, image, version \\ :thumb) do
    image = StoreHall.FileUploader.url({image, item}, version)

    case String.ends_with?(image, to_string(version) <> "-") do
      false -> image
      true -> ""
    end

    # case File.exists?("." <> image) do
    #   false -> ""
    #   true -> image
    # end
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
    |> Multi.insert(:insert, Item.changeset(%Item{}, prepare_images(item)))
    |> upsert_images(item, :insert)
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        {:ok, multi.insert |> Reactions.preload_reaction(Repo, item["user_id"], "item")}

      {:error, _op, value, _changes} ->
        {:error, value}
    end
  end

  defp init_rating(item) do
    score = Users.get_user!(Map.get(item, "user_id")).details["rating"]["score"]

    item
    |> put_in(
      ["details", "rating"],
      %{"count" => 0, "score" => score}
    )
  end

  defp prepare_images(item) do
    case item["images"] do
      nil ->
        item

      images ->
        new_images =
          images
          |> Enum.map(fn image ->
            rename_duplicated(image, item).filename
          end)

        item
        |> put_in(["details", "images"], item["details"]["images"] ++ new_images)
    end
  end

  defp strip_ext(image_name) do
    image_name |> Path.basename() |> Path.rootname()
  end

  defp rename_duplicated(image, item) do
    case Map.get(item, "details")["images"] do
      nil ->
        image

      saved_images ->
        saved_images
        |> Enum.filter(fn saved_image ->
          String.contains?(strip_ext(saved_image), strip_ext(image.filename))
        end)
        |> case do
          [] ->
            image

          similar_images ->
            new_name =
              "#{strip_ext(image.filename)}-#{length(similar_images) + 1}#{
                Path.extname(image.filename)
              }"

            Map.put(image, :filename, new_name)
        end
    end
  end

  defp upsert_images(multi, item, multi_name) do
    case item["images"] do
      nil ->
        multi

      images ->
        multi
        |> Multi.run(:upsert_images, fn _repo, %{^multi_name => item_with_user_id} ->
          images
          |> rename_duplicated(item_with_user_id)
          |> Enum.reduce({:ok, "no error"}, fn image, acc ->
            case FileUploader.store({rename_duplicated(image, item), item_with_user_id}) do
              {:ok, _value} -> acc
              {:error, value} -> {:error, value}
            end
          end)
        end)
    end
  end

  defp clean_images(multi, item, images_to_remove) do
    multi
    |> Multi.run(:clean_images, fn _repo, _ ->
      images_to_remove
      |> Enum.reduce({:ok, "no error"}, fn image, _acc ->
        FileUploader.delete({image, item})
      end)

      # File.rmdir(FileUploader.storage_dir(nil, {nil, item}))
      {:ok, "no error"}
    end)
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
            |> get_parents
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
    |> Multi.update(:update, Item.changeset(item, prepare_images(attrs)))
    |> clean_images(item, details_to_remove(item, attrs, "images"))
    |> upsert_images(attrs, :update)
    |> clean_filters()
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        {:ok, multi.update |> Reactions.preload_reaction(Repo, item["user_id"], "item")}

      {:error, _op, value, _changes} ->
        {:error, value}
    end
  end

  def update_list_tags(multi, item, attrs) do
    multi
    |> update_list_filters("tags", details_to_add(item, attrs, "tags"))
    |> update_list_filters("tags", details_to_remove(item, attrs, "tags"), -1)
  end

  def details_to_add(item, attrs, detail_type) do
    old_details = item.details[detail_type]
    new_details = attrs["details"][detail_type]

    MapSet.difference(MapSet.new(new_details), MapSet.new(old_details))
    |> MapSet.to_list()
  end

  def details_to_remove(item, attrs, detail_type) do
    old_details = item.details[detail_type]
    new_details = attrs["details"][detail_type]

    MapSet.difference(MapSet.new(old_details), MapSet.new(new_details))
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
    |> clean_images(item, item.details["images"])
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

  def decode_params(item_params = %{"details" => details}) when is_binary(details) do
    item_params
    |> put_in(
      ["details"],
      Jason.decode!(details)
    )
  end

  def decode_params(item_params), do: item_params

  def item_filters() do
    Filters |> Repo.all() |> Filters.to_map()
  end
end
