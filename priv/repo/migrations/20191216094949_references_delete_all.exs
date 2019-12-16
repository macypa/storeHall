defmodule StoreHall.Repo.Migrations.ReferencesDeleteAll do
  use Ecto.Migration

  def up do
      drop constraint :user_relations, "user_relations_user_id_fkey"
      drop constraint :user_relations, "user_relations_related_to_user_id_fkey"
      alter table(:user_relations) do
        modify :user_id, references(:users, [type: :string, on_delete: :delete_all])
        modify :related_to_user_id, references(:users, [type: :string, on_delete: :delete_all])
      end

      drop constraint :user_labels, "user_labels_user_id_fkey"
      alter table(:user_labels) do
        modify :user_id, references(:users, [type: :string, on_delete: :delete_all])
      end

      drop constraint :user_reactions, "user_reactions_user_id_fkey"
      alter table(:user_reactions) do
        modify :user_id, references(:users, [type: :string, on_delete: :delete_all])
      end

      drop constraint :user_comments, "user_comments_user_id_fkey"
      drop constraint :user_comments, "user_comments_author_id_fkey"
      alter table(:user_comments) do
        modify :user_id, references(:users, [type: :string, on_delete: :delete_all])
        modify :author_id, references(:users, [type: :string, on_delete: :delete_all])
      end

      drop constraint :user_ratings, "user_ratings_user_id_fkey"
      drop constraint :user_ratings, "user_ratings_author_id_fkey"
      alter table(:user_ratings) do
        modify :user_id, references(:users, [type: :string, on_delete: :delete_all])
        modify :author_id, references(:users, [type: :string, on_delete: :delete_all])
      end

      drop constraint :items, "items_user_id_fkey"
      alter table(:items) do
        modify :user_id, references(:users, [type: :string, on_delete: :delete_all])
      end

      drop constraint :item_comments, "item_comments_user_id_fkey"
      drop constraint :item_comments, "item_comments_author_id_fkey"
      alter table(:item_comments) do
        modify :user_id, references(:users, [type: :string, on_delete: :delete_all])
        modify :author_id, references(:users, [type: :string, on_delete: :delete_all])
      end

      drop constraint :item_ratings, "item_ratings_user_id_fkey"
      drop constraint :item_ratings, "item_ratings_author_id_fkey"
      alter table(:item_ratings) do
        modify :user_id, references(:users, [type: :string, on_delete: :delete_all])
        modify :author_id, references(:users, [type: :string, on_delete: :delete_all])
      end

      drop constraint :chat_messages, "chat_messages_user_id_fkey"
      drop constraint :chat_messages, "chat_messages_author_id_fkey"
      drop constraint :chat_messages, "chat_messages_owner_id_fkey"
      alter table(:chat_messages) do
        modify :user_id, references(:users, [type: :string, on_delete: :delete_all])
        modify :author_id, references(:users, [type: :string, on_delete: :delete_all])
        modify :owner_id, references(:users, [type: :string, on_delete: :delete_all])
      end
  end

  def down do
      drop constraint :user_relations, "user_relations_user_id_fkey"
      drop constraint :user_relations, "user_relations_related_to_user_id_fkey"
      alter table(:user_relations) do
        modify :user_id, references(:users, [type: :string, on_delete: :nothing])
        modify :related_to_user_id, references(:users, [type: :string, on_delete: :nothing])
      end

      drop constraint :user_labels, "user_labels_user_id_fkey"
      alter table(:user_labels) do
        modify :user_id, references(:users, [type: :string, on_delete: :nothing])
      end

      drop constraint :user_reactions, "user_reactions_user_id_fkey"
      alter table(:user_reactions) do
        modify :user_id, references(:users, [type: :string, on_delete: :nothing])
      end

      drop constraint :user_comments, "user_comments_user_id_fkey"
      drop constraint :user_comments, "user_comments_author_id_fkey"
      alter table(:user_comments) do
        modify :user_id, references(:users, [type: :string, on_delete: :nothing])
        modify :author_id, references(:users, [type: :string, on_delete: :nothing])
      end

      drop constraint :user_ratings, "user_ratings_user_id_fkey"
      drop constraint :user_ratings, "user_ratings_author_id_fkey"
      alter table(:user_ratings) do
        modify :user_id, references(:users, [type: :string, on_delete: :nothing])
        modify :author_id, references(:users, [type: :string, on_delete: :nothing])
      end

      drop constraint :items, "items_user_id_fkey"
      alter table(:items) do
        modify :user_id, references(:users, [type: :string, on_delete: :nothing])
      end

      drop constraint :item_comments, "item_comments_user_id_fkey"
      drop constraint :item_comments, "item_comments_author_id_fkey"
      alter table(:item_comments) do
        modify :user_id, references(:users, [type: :string, on_delete: :nothing])
        modify :author_id, references(:users, [type: :string, on_delete: :nothing])
      end

      drop constraint :item_ratings, "item_ratings_user_id_fkey"
      drop constraint :item_ratings, "item_ratings_author_id_fkey"
      alter table(:item_ratings) do
        modify :user_id, references(:users, [type: :string, on_delete: :nothing])
        modify :author_id, references(:users, [type: :string, on_delete: :nothing])
      end

      drop constraint :chat_messages, "chat_messages_user_id_fkey"
      drop constraint :chat_messages, "chat_messages_author_id_fkey"
      drop constraint :chat_messages, "chat_messages_owner_id_fkey"
      alter table(:chat_messages) do
        modify :user_id, references(:users, [type: :string, on_delete: :nothing])
        modify :author_id, references(:users, [type: :string, on_delete: :nothing])
        modify :owner_id, references(:users, [type: :string, on_delete: :nothing])
      end

  end
end
