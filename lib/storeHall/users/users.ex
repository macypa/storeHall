defmodule StoreHall.Users do
  import Ecto.Query, warn: false
  alias StoreHall.Repo
  alias StoreHall.DeepMerge

  alias StoreHall.Users.User
  alias StoreHall.Users.Settings

  alias StoreHall.UserFilter
  alias StoreHall.DefaultFilter

  def list_users(conn, _params) do
    apply_filters(conn)
    |> Repo.all()
  end

  def apply_filters(conn) do
    User
    |> DefaultFilter.sort_filter(conn)
    |> DefaultFilter.paging_filter(conn)
    |> UserFilter.search_filter(conn)
  end

  def get_user!(id, repo \\ Repo) do
    user = repo.get!(User, id)
    update_default_user_details(user, repo)
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
    user = get_user!(id)

    settings =
      Repo.get(Settings, id)
      |> case do
        nil -> %Settings{id: user.id}
        settings -> settings
      end
      |> Map.get(:settings)

    Map.put(user, :settings, settings)
  end

  def update_user(%User{} = user, attrs) do
    upsert_settings(user, Map.get(attrs, "settings"))

    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def load_settings(%User{} = user) do
    settings =
      upsert_settings(user)
      |> Map.get(:settings)

    Map.put(user, :settings, settings)
  end

  defp upsert_settings(user, changes \\ %{}) do
    settings =
      case Repo.get(Settings, user.id) do
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
    |> Repo.insert_or_update()
    |> case do
      {:ok, model} -> model
    end
  end

  def delete_user(%User{} = user) do
    Repo.delete(user)

    case Repo.get(Settings, user.id) do
      nil -> {:ok}
      user_setting -> Repo.delete(user_setting)
    end
  end

  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end

  def decode_user_params(user_params) do
    user_params
    |> put_in(
      ["settings", "labels"],
      Jason.decode!(get_in(user_params, ["settings", "labels"]))
    )
  end
end
