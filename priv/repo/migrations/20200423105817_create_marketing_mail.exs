defmodule StoreHall.Repo.Migrations.CreateMarketingMail do
  use Ecto.Migration

  def change do
    create table(:marketing_mails) do
      add :from_user_id, references(:users, type: :string, on_delete: :delete_all)
      add :sent_to_user_ids, :map
      add :unread_by_user_ids, :map
      add :claimed_by_user_ids, :map
      add :deleted_by_user_ids, :map
      add :details, :map

      timestamps(type: :timestamptz)
    end
  end
end
