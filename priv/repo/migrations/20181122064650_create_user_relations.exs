defmodule StoreHall.Repo.Migrations.CreateUserRelations do
  use Ecto.Migration

  def change do
    create table(:user_relations) do
      add :user_id, :string
      add :related_to_user_id, :string
      add :type, :string

      timestamps()
    end

    create unique_index(:user_relations, [:type, :related_to_user_id, :user_id], name: :unique_relation)

  end
end
