defmodule StoreHall.Repo.Migrations.CreateItems do
  use Ecto.Migration

  def change do
    create table(:items) do
      add :name, :string
      add :user_id, :integer
      add :details, :map

      timestamps()
    end

  end
end
