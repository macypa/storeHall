defmodule StoreHall.Repo.Migrations.CreateUserRatings do
  use Ecto.Migration

  def change do
    create table(:user_ratings) do
      add :author_id, :string
      add :rating_id, :integer
      add :user_id, :string
      add :details, :map

      timestamps()
    end

  end
end
