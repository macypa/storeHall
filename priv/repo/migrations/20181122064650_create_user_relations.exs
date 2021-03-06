defmodule StoreHall.Repo.Migrations.CreateUserRelations do
  use Ecto.Migration

  def change do
    create table(:user_relations) do
      add :user_id, references(:users, [type: :string])
      add :related_to_user_id, references(:users, [type: :string])
      add :type, :string

      timestamps(type: :timestamptz)
    end

    create unique_index(:user_relations, [:type, :related_to_user_id, :user_id], name: :unique_relation)

  end
end
