defmodule StoreHall.Repo.Migrations.CreateItemComments do
  use Ecto.Migration

  def change do
    create table(:item_comments) do
      add :item_id, :integer
      add :comment_id, :integer
      add :user_id, :string
      add :author_id, :string
      add :details, :map

      timestamps()
    end

  end
end
