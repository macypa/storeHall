defmodule StoreHall.Users do
  import Ecto.Query, warn: false
  alias StoreHall.Repo
  alias StoreHall.DeepMerge

  alias StoreHall.Users.User
  alias StoreHall.Users.Settings

  def list_users(params) do
    {users, rummage} =
      User
      |> Rummage.Ecto.rummage(params["rummage"])

    users =
      users
      |> Repo.all()

    {users, rummage}
  end

  def get_user!(id, repo \\ Repo) do
    user = repo.get!(User, id)
    update_default_user_details(user, repo)
  end

  defp update_default_user_details(user, repo \\ Repo) do
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
      Repo.get!(Settings, id)
      |> Map.get(:settings)

    Map.put(user, :settings, settings)
  end

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
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
    Repo.delete(Repo.get!(Settings, user.id))
  end

  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end
end
