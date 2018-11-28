defmodule StoreHall.Repo.Migrations.CreateItemFilters do
  use Ecto.Migration

  def change do
    create table(:item_filters) do
      add :name, :string
      add :type, :string
      add :count, :integer

      timestamps()
    end

  end
end
