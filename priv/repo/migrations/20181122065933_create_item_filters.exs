defmodule StoreHall.Repo.Migrations.CreateItemFilters do
  use Ecto.Migration

  def change do
    create table(:item_filters) do
      add :type, :string
      add :list, :map

      timestamps()
    end

  end
end
