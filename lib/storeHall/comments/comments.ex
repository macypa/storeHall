defmodule StoreHall.Comments do
  @moduledoc """
  The Comments context.
  """

  import Ecto.Query, warn: false
  alias StoreHall.Repo

  alias StoreHall.Comments.ItemComment
  alias StoreHall.Comments.UserComment

  def list_item_comments do
    Repo.all(ItemComment)
  end

  def list_user_comments do
    Repo.all(UserComment)
  end

  def get_item_comment!(id), do: Repo.get!(ItemComment, id)

  def get_comments_for_item(id) do
    ItemComment
    |> where(item_id: ^id)
    |> Repo.all()
  end

  def get_comments_for_user(id) do
    UserComment
    |> where(user_id: ^id)
    |> Repo.all()
  end

  def create_item_comment(attrs \\ %{}) do
    %ItemComment{}
    |> ItemComment.changeset(attrs)
    |> Repo.insert()
  end

  def create_user_comment(attrs \\ %{}) do
    %UserComment{}
    |> UserComment.changeset(attrs)
    |> Repo.insert()
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
