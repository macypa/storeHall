defmodule StoreHall.Repo.Migrations.AddUserDetailsField do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :details, :map
    end
  end
end
