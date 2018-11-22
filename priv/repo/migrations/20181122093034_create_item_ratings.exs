defmodule StoreHall.Repo.Migrations.CreateItemRatings do
  use Ecto.Migration

  def change do
    create table(:item_ratings) do
      add :item_id, :integer
      add :type, :string
      add :parent_rating_id, :integer
      add :from_user_id, :integer
      add :content, :map

      timestamps()
    end

  end
end
