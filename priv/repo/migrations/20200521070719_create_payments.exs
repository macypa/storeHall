defmodule StoreHall.Repo.Migrations.CreatePayments do
  use Ecto.Migration

  def change do
    create table(:payments) do
      add :user_id, references(:users, type: :string, on_delete: :delete_all)
      add :invoice, :bigint
      add :details, :map

      timestamps(type: :timestamptz)
    end

    create unique_index(:payments, [:invoice], name: :unique_invoice)
  end
end
