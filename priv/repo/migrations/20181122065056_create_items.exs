defmodule StoreHall.Repo.Migrations.CreateItems do
  use Ecto.Migration


  def change do
    create table(:items) do
      add :name, :string
      add :user_id, references(:users, [type: :string])
      add :details, :map

      timestamps()
    end

    create unique_index(:items, [:name, :user_id], name: :unique_name_for_user)
  end
end
