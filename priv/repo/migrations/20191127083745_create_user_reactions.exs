defmodule StoreHall.Repo.Migrations.CreateUserReactions do
  use Ecto.Migration

  def change do

    create table(:user_reactions) do
      add :user_id, references(:users, [type: :string])
      add :reacted_to, :integer
      add :type, :string
      add :reaction, :string

      timestamps(type: :timestamptz)
    end

    create unique_index(:user_reactions, [:type, :reaction, :reacted_to, :user_id], name: :unique_reaction)

  end
end
