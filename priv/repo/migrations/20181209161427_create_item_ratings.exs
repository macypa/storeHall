defmodule StoreHall.Repo.Migrations.CreateItemRatings do
  use Ecto.Migration

  def change do
    create table(:item_ratings) do
      add :item_id, :integer
      add :author_id, :string
      add :rating_id, :integer
      add :user_id, :string
      add :details, :map

      timestamps()
    end

  end
end
