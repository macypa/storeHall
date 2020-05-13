defmodule StoreHall.Users do
  import Ecto.Query, warn: false
  alias StoreHall.Repo
  alias StoreHall.DeepMerge
  alias StoreHall.ParseNumbers
  alias Ecto.Multi

  alias StoreHall.Images
  alias StoreHall.Items
  alias StoreHall.Users.User
  alias StoreHall.Users.Settings

  alias StoreHall.UserFilter
  alias StoreHall.DefaultFilter

  def list_users(params, current_user_id \\ nil) do
    users_info =
      apply_filters(params, current_user_id)
      |> subquery()
      |> select([u], %{
        count: count(u.id),
        max_credits: fragment("max((?.marketing_info->>'mail_credits_ask')::integer)", u)
      })
      |> Repo.one()

    users_info
    |> Map.put(:total_cost_credits, users_info.count * users_info.max_credits)
  end

  def list_user_ids(params, current_user_id \\ nil) do
    apply_filters(params, current_user_id)
    |> subquery()
    |> select([u], u.id)
    |> Repo.all()
  end

  def apply_filters(params, current_user_id) do
    User
    |> UserFilter.except_user_id(current_user_id)
    |> UserFilter.with_marketing_consent()
    |> DefaultFilter.paging_filter(params, -1)
    |> DefaultFilter.sort_filter(params |> Map.put_new("filter", %{"sort" => "inserted_at:desc"}))
    |> UserFilter.search_filter(params)
  end

  def preload_users(model, repo \\ Repo) do
    model
    |> repo.preload(user: from(u in User) |> add_select_fields_for_preload([]))
    |> clean_preloaded_user(:user, [])
  end

  def preload_author(model, repo \\ Repo) do
    model
    |> repo.preload(author: from(u in User) |> add_select_fields_for_preload([]))
    |> clean_preloaded_user(:author, [:info])
  end

  def preload_sender(model, repo \\ Repo) do
    model
    |> repo.preload(from_user: from(u in User) |> add_select_fields_for_preload([]))
    |> clean_preloaded_user(:from_user, [:info])
  end

  def clean_preloaded_user(model_list, user_field, user_fields_to_drop)
      when is_list(model_list) do
    model_list
    |> Enum.map(fn model ->
      clean_preloaded_user(model, user_field, user_fields_to_drop)
    end)
  end

  def clean_preloaded_user(model, user_field, user_fields_to_drop) do
    model
    |> Map.put(
      user_field,
      model
      |> Map.get(user_field)
      |> Map.merge(user_fields_to_drop |> Enum.map(fn key -> {key, nil} end) |> Map.new())
      |> Map.put(:image, get_user_image(Map.get(model, user_field)))
    )
  end

  def get!(id, select_fields \\ [], repo \\ Repo) do
    get_user!(id, select_fields, repo)
  end

  def get_user!(id, select_fields \\ [], repo \\ Repo) do
    User
    |> add_select_fields(select_fields)
    |> repo.get!(id)
  end

  def get_user(id, select_fields \\ [], repo \\ Repo) do
    User
    |> add_select_fields(select_fields)
    |> repo.get(id)
  end

  def add_select_fields_for_preload(query, []) do
    query
    |> select(^User.base_fields())
  end

  def add_select_fields(query, []) do
    query
    |> select(^User.fields())
  end

  def add_select_fields(query, select_fields) do
    query
    |> select(
      ^(User.fields()
        |> Kernel.++(select_fields))
    )
  end

  def get_user_with_settings!(id, select_fields \\ []) do
    get_user!(id, select_fields)
    |> load_settings()
  end

  def get_user_with_settings(id, select_fields \\ []) do
    get_user(id, select_fields)
    |> case do
      nil -> nil
      user -> load_settings(user)
    end
  end

  def load_settings(%User{} = user) do
    settings =
      upsert_settings(user)
      |> case do
        {:ok, model} -> model
      end
      |> Map.get(:settings)

    Map.put(user, :settings, settings)
  end

  defp deep_merge_map(attrs, user) do
    attrs
    |> deep_merge_map(user, "settings")
    |> deep_merge_map(user, "details")
    |> deep_merge_map(user, "info")
    |> deep_merge_map(user, "marketing_info")
  end

  defp deep_merge_map(attrs, map, key) do
    case Map.has_key?(attrs, key) and Map.has_key?(map, String.to_atom(key)) do
      true ->
        attrs
        |> Map.put(key, Map.get(map, String.to_atom(key)) |> Map.merge(attrs[key]))

      false ->
        attrs
    end
  end

  defp default_values_instead_of_nil(attrs) do
    case attrs["marketing_info"] do
      nil ->
        attrs

      _ ->
        case attrs["marketing_info"]["mail_credits_ask"] do
          nil -> attrs |> put_in(["marketing_info", "mail_credits_ask"], 0)
          _ -> attrs
        end
    end
  end

  def update_user(%User{} = user, attrs) do
    attrs = deep_merge_map(attrs, user) |> default_values_instead_of_nil

    Ecto.Multi.new()
    |> upsert_settings_on_multi(user, Map.get(attrs, "settings"))
    |> Multi.update(:update, User.changeset(user, prepare_for_insert(attrs)))
    |> Images.clean_images(user, details_to_remove(user, attrs, "images"))
    |> Images.upsert_images(attrs, :update)
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        {:ok, multi.update |> load_settings()}

      {:error, _op, value, _changes} ->
        {:error, value}
    end
  end

  defp prepare_for_insert(user) do
    user
    |> Images.prepare_images()
    |> ParseNumbers.prepare_number(["marketing_info", "mail_credits_ask"])
  end

  defp upsert_settings(user, changes \\ %{}, repo \\ Repo) do
    settings =
      case repo.get(Settings, user.id) do
        nil -> %Settings{id: user.id}
        settings -> settings
      end

    changes =
      %Settings{id: user.id}
      |> DeepMerge.merge(settings)
      |> DeepMerge.merge(Map.put(%{}, :settings, changes))
      |> Map.get(:settings)

    settings
    |> Settings.changeset(Map.put(%{}, :settings, changes))
    |> repo.insert_or_update()
  end

  defp upsert_settings_on_multi(multi, user, changes) do
    multi
    |> Ecto.Multi.run(:upsert_settings, fn repo, _ ->
      upsert_settings(user, changes, repo)
    end)
  end

  def details_to_remove(user, attrs, detail_type) do
    old_details = user.details[detail_type]

    attrs["details"][detail_type]
    |> case do
      nil ->
        []

      new_details ->
        MapSet.difference(MapSet.new(old_details), MapSet.new(new_details))
        |> MapSet.to_list()
    end
  end

  def delete_user(%User{} = user) do
    delete_items_for_user(user)

    Ecto.Multi.new()
    |> Ecto.Multi.run(:settings, fn repo, _changes ->
      case repo.get(Settings, user.id) do
        nil -> {:error, :not_found}
        settings -> {:ok, settings}
      end
    end)
    |> Ecto.Multi.delete(:delete_settings, fn %{settings: settings} ->
      settings
    end)
    |> Images.clean_images(user, user.details["images"])
    |> Multi.delete(:delete_user, user)
    |> Repo.transaction()
    |> case do
      {:ok, _multi} ->
        {:ok}

      {:error, _op, _value, _changes} ->
        {:error}
    end
  end

  def delete_items_for_user(%User{} = user) do
    user =
      user
      |> Repo.preload(:items)

    user.items
    |> Enum.each(fn item ->
      Items.delete_item(item)
    end)
  end

  def get_user_image(user) do
    case Images.cover_image(user) do
      nil -> user.image
      image -> image
    end
  end

  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end
end
