defmodule StoreHall.Repo.Migrations.CreateUserLabels do
  use Ecto.Migration

  def change do
    create table(:user_labels) do
      add :label, :string
      add :item_id, :integer
      add :user_id, :string

      timestamps()
    end

    create unique_index(:user_labels, [:label, :item_id, :user_id], name: :unique_label)

  end
end
