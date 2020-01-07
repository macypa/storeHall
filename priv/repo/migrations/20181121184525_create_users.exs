defmodule StoreHall.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :string, primary_key: true
      add :name, :string
      add :email, :string
      add :provider, :string

      timestamps(type: :timestamptz)
    end

  end
end
