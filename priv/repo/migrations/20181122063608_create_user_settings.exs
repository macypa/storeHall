defmodule StoreHall.Repo.Migrations.CreateUserSettings do
  use Ecto.Migration

  def change do
    create table(:user_settings, primary_key: false) do
      add :id, :string, primary_key: true
      add :settings, :map

      timestamps(type: :timestamptz)
    end

  end
end
