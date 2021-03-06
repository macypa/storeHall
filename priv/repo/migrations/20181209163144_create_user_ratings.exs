defmodule StoreHall.Repo.Migrations.CreateUserRatings do
  use Ecto.Migration

  def change do
    create table(:user_ratings) do
      add :author_id, references(:users, [type: :string])
      add :user_id, references(:users, [type: :string])
      add :rating_id, :integer
      add :details, :map

      timestamps(type: :timestamptz)
    end

    create unique_index(:user_ratings,
                        [:author_id, :user_id],
                        where: "rating_id IS NULL",
                        name: :unique_user_rating)

  end
end
