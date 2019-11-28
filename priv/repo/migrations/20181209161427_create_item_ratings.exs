defmodule StoreHall.Repo.Migrations.CreateItemRatings do
  use Ecto.Migration

  def change do
    create table(:item_ratings) do
      add :item_id, :integer
      add :author_id, references(:users, [type: :string])
      add :user_id, references(:users, [type: :string])
      add :rating_id, :integer
      add :details, :map

      timestamps(type: :timestamptz)
    end

    create unique_index(:item_ratings,
                        [:item_id, :author_id, :user_id],
                        where: "rating_id IS NULL",
                        name: :unique_item_rating)

  end
end
