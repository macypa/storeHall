defmodule StoreHall.Repo.Migrations.CreateChatMessages do
  use Ecto.Migration

    def change do
      create table(:chat_messages) do
        add :author_id, :string
        add :owner_id, :string
        add :item_id, :integer
        add :user_id, :string
        add :details, :map

        timestamps()
      end

    end
end
