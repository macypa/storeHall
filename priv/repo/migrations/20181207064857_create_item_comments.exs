defmodule StoreHall.Repo.Migrations.CreateItemComments do
  use Ecto.Migration

  def change do
    create table(:item_comments) do
      add :author_id, references(:items)
      add :user_id, references(:items)
      add :item_id, :integer
      add :comment_id, :integer
      add :details, :map

      timestamps()
    end

  end
end
