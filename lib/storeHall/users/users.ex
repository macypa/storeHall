defmodule StoreHall.Users do
  import Ecto.Query, warn: false
  alias StoreHall.Repo
  alias StoreHall.DeepMerge
  alias Ecto.Multi

  alias StoreHall.Images
  alias StoreHall.Items
  alias StoreHall.Users.User
  alias StoreHall.Users.Settings

  alias StoreHall.UserFilter
  alias StoreHall.DefaultFilter

  def list_users(params) do
    apply_filters(params)
    |> Repo.all()
  end

  def apply_filters(params) do
    User
    |> add_select_fields([:marketing_info])
    |> UserFilter.with_marketing_consent()
    |> DefaultFilter.sort_filter(params |> Map.put_new("filter", %{"sort" => "inserted_at:desc"}))
    |> UserFilter.search_filter(params)
  end

  def preload_users(query, repo) do
    query
    |> repo.preload(user: from(u in User) |> add_select_fields([]))
  end

  def preload_author(query, repo) do
    query
    |> repo.preload(author: from(u in User) |> add_select_fields([]))
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

  def add_select_fields(query, []) do
    query
    |> select(
      ^(User.fields()
        |> List.delete(:marketing_info)
        |> List.delete(:info))
    )
  end

  def add_select_fields(query, select_fields) do
    query
    |> select(
      ^(User.fields()
        |> List.delete(:marketing_info)
        |> List.delete(:info)
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
        |> Map.put(key, Map.get(map, String.to_atom(key)) |> DeepMerge.merge(attrs[key]))

      false ->
        attrs
    end
  end

  def update_user(%User{} = user, attrs) do
    attrs = deep_merge_map(attrs, user)

    Ecto.Multi.new()
    |> upsert_settings_on_multi(user, Map.get(attrs, "settings"))
    |> Multi.update(:update, User.changeset(user, Images.prepare_images(attrs)))
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

  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end
end
