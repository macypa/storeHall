defmodule StoreHall.Repo.Migrations.CreateItemRatings do
  use Ecto.Migration

  def change do
    create table(:item_ratings) do
      add :item_id, :integer
      add :author_id, :string
      add :user_id, :string
      add :details, :map

      timestamps()
    end

    create unique_index(:item_ratings, [:item_id, :author_id, :user_id], name: :unique_item_rating)

  end
end
