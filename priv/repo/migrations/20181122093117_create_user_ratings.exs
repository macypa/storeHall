defmodule StoreHall.Repo.Migrations.CreateUserRatings do
  use Ecto.Migration

  def change do
    create table(:user_ratings) do
      add :user_id, :integer
      add :type, :string
      add :parent_rating_id, :integer
      add :from_user_id, :integer
      add :content, :map

      timestamps()
    end

  end
end
