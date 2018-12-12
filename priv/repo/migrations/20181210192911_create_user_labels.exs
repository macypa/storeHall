defmodule StoreHall.Repo.Migrations.CreateUserLabels do
  use Ecto.Migration

  def change do
    create table(:user_labels) do
      add :label, :string
      add :item_id, :integer
      add :user_id, :string

      timestamps()
    end

  end
end
