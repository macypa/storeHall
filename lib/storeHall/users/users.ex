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

  def list_users(params \\ nil) do
    apply_filters(params)
    |> Repo.all()
    |> Images.append_images()
  end

  def apply_filters(params) do
    User
    |> DefaultFilter.sort_filter(params)
    |> DefaultFilter.paging_filter(params)
    |> UserFilter.search_filter(params)
  end

  def get!(id, repo \\ Repo) do
    get_user!(id, repo)
  end

  def get_user!(id, repo \\ Repo) do
    User
    |> repo.get!(id)
    |> update_default_user_details(repo)
  end

  def get_user(id, repo \\ Repo) do
    User
    |> repo.get(id)
    |> case do
      nil -> nil
      user -> update_default_user_details(user, repo)
    end
  end

  defp update_default_user_details(user, repo) do
    details =
      %User{}.details
      |> DeepMerge.merge(user.details)

    user
    |> User.changeset(%{details: details})
    |> repo.update()
    |> case do
      {:ok, updated_user} -> updated_user
      {:error, _error} -> user
    end
  end

  def get_user_with_settings!(id) do
    get_user!(id)
    |> load_settings()
  end

  def get_user_with_settings(id) do
    get_user(id)
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

  def update_user(%User{} = user, attrs) do
    Ecto.Multi.new()
    |> upsert_settings_on_multi(user, Map.get(attrs, "settings"))
    |> Multi.update(:update, User.changeset(user, Images.prepare_images(attrs)))
    |> Images.clean_images(user, details_to_remove(user, attrs, "images"))
    |> Images.upsert_images(attrs, :update)
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        {:ok, multi.update}

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

  def decode_params(user_params = %{"details" => details}) when is_binary(details) do
    user_params
    |> put_in(
      ["details"],
      Jason.decode!(details)
    )
    |> decode_settings()
  end

  def decode_params(user_params = %{"details" => details}) when is_map(details) do
    user_params
    |> put_in(
      ["details"],
      details
      |> decode_param_in("images")
      |> decode_param_in("videos")
      |> decode_param_in("address")
      |> decode_param_in("mail")
      |> decode_param_in("web")
      |> decode_param_in("open")
    )
    |> decode_settings()
  end

  defp decode_param_in(map, param) do
    case Map.has_key?(map, param) do
      true ->
        map
        |> put_in([param], Jason.decode!(map[param]))

      false ->
        map
    end
  end

  def decode_params(user_params), do: decode_settings(user_params)

  defp decode_settings(user_params = %{"settings" => settings}) do
    user_params
    |> put_in(
      ["settings"],
      settings
      |> decode_filter_params("filters")
    )
  end

  defp decode_settings(user_params), do: user_params

  defp decode_filter_params(map, param) do
    case Map.has_key?(map, param) do
      true ->
        map
        |> put_in(
          [param],
          map[param]
          |> Enum.reduce(%{}, fn {k, v}, acc ->
            case v do
              "" ->
                acc

              _ ->
                acc
                |> Map.put(k, Jason.decode!(v))
            end
          end)
        )

      false ->
        map
    end
  end
end
