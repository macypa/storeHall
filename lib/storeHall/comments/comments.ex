defmodule StoreHall.Comments do
  @moduledoc """
  The Comments context.
  """

  import Ecto.Query, warn: false
  alias StoreHall.Repo
  alias Ecto.Multi

  alias StoreHall.Comments.ItemComment
  alias StoreHall.Comments.UserComment
  alias StoreHall.Items
  alias StoreHall.Items.Item
  alias StoreHall.Users
  alias StoreHall.Users.User

  def list_item_comments do
    Repo.all(ItemComment)
  end

  def list_user_comments do
    Repo.all(UserComment)
  end

  def get_item_comment!(id), do: Repo.get!(ItemComment, id)

  def for_item(id) do
    ItemComment
    |> where(item_id: ^id)
    # |> where([i], is_nil(i.comment_id))
    |> Repo.all()
  end

  def for_user(id) do
    UserComment
    |> where(user_id: ^id)
    |> Repo.all()
  end

  def create_item_comment(comment \\ %{}) do
    Multi.new()
    |> update_item_comment_count(comment["item_id"])
    |> Multi.insert(:insert, ItemComment.changeset(%ItemComment{}, comment))
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        {:ok, multi.insert}

      {:error, _op, value, _changes} ->
        {:error, value}
    end
  end

  def create_user_comment(comment \\ %{}) do
    Multi.new()
    |> update_user_comment_count(comment["user_id"])
    |> Multi.insert(:insert, UserComment.changeset(%UserComment{}, comment))
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        {:ok, multi.insert}

      {:error, _op, value, _changes} ->
        {:error, value}
    end
  end

  def update_item_comment_count(multi, item_id) do
    multi
    |> Multi.run(:item, fn repo, %{} ->
      {:ok, Items.get_item!(item_id, repo)}
    end)
    |> Multi.run(:calc_item_comment_count, fn repo, %{item: item} ->
      calculate_comment_count(repo, Item, item)
    end)
    |> update_user_comment_count(nil)
  end

  def update_user_comment_count(multi, user_id) do
    multi
    |> Multi.run(:user, fn repo, changes ->
      case changes do
        %{item: item} -> {:ok, Users.get_user!(item.user_id, repo)}
        _ -> {:ok, Users.get_user!(user_id, repo)}
      end
    end)
    |> Multi.run(:calc_user_comment_count, fn repo, %{user: user} ->
      calculate_comment_count(repo, User, user)
    end)
  end

  def calculate_comment_count(repo, query, item_or_user) do
    query =
      from u in query,
        where: u.id == ^item_or_user.id,
        update: [
          set: [
            details:
              fragment(
                " jsonb_set(details, '{comments_count}', (COALESCE(details->>'comments_count','0')::int + 1)::text::jsonb) "
              )
          ]
        ]

    {:ok, repo.update_all(query, [])}
  end

  def construct_item_comment(attrs \\ %{}) do
    %ItemComment{}
    |> ItemComment.changeset(attrs)
  end

  def construct_user_comment(attrs \\ %{}) do
    %UserComment{}
    |> UserComment.changeset(attrs)
  end
end
