defmodule StoreHall.Repo.Migrations.CreateUserComments do
  use Ecto.Migration

  def change do
    create table(:user_comments) do
      add :author_id, references(:users, [type: :string])
      add :user_id, references(:users, [type: :string])
      add :comment_id, :integer
      add :details, :map

      timestamps(type: :timestamptz)
    end

  end
end
