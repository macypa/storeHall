defmodule StoreHall.Repo.Migrations.CreateUserComments do
  use Ecto.Migration

  def change do
    create table(:user_comments) do
      add :author_id, :string
      add :comment_id, :integer
      add :user_id, :string
      add :details, :map

      timestamps()
    end

  end
end
