defmodule StoreHall.Repo.Migrations.CreateItemComments do
  use Ecto.Migration

  def change do
    create table(:item_comments) do
      add :author_id, references(:users, [type: :string])
      add :user_id, references(:users, [type: :string])
      add :item_id, :integer
      add :comment_id, :integer
      add :details, :map

      timestamps(type: :timestamptz)
    end

  end
end
