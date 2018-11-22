defmodule StoreHall.Repo.Migrations.CreateUserRelations do
  use Ecto.Migration

  def change do
    create table(:user_relations) do
      add :user_id, :integer
      add :related_to_user_id, :integer
      add :type, :string

      timestamps()
    end

  end
end
