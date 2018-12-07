defmodule StoreHall.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :item_id, :integer
      add :comment_id, :integer
      add :user_id, :string
      add :author_id, :string
      add :details, :map

      timestamps()
    end

  end
end
