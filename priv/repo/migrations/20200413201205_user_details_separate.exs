defmodule StoreHall.Repo.Migrations.UserDetailsSeparate do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :info, :map
      add :marketing_info, :map
    end
  end
end
