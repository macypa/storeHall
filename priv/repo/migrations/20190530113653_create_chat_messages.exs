defmodule StoreHall.Repo.Migrations.CreateChatMessages do
  use Ecto.Migration

    def change do
      create table(:chat_messages) do
        add :author_id, references(:users, [type: :string])
        add :owner_id, references(:users, [type: :string])
        add :user_id, references(:users, [type: :string])
        add :item_id, references(:items)
        add :details, :map

        timestamps()
      end

    end
end
