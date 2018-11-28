defmodule StoreHall.Repo.Migrations.CreateUserSettings do
  use Ecto.Migration

  def change do
    create table(:user_settings) do
      add :user_id, :string
      add :settings, :map

      timestamps()
    end

  end
end
