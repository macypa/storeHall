defmodule StoreHall.Repo.Migrations.CreateUserRatings do
  use Ecto.Migration

  def change do
    create table(:user_ratings) do
      add :author_id, references(:users, [type: :string])
      add :user_id, references(:users, [type: :string])
      add :details, :map

      timestamps()
    end

    create unique_index(:user_ratings, [:author_id, :user_id], name: :unique_user_rating)

  end
end
