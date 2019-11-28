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
  alias StoreHall.DefaultFilter

  def preload_for(item_user, current_user_id, params) do
    item_user
    |> Map.put(
      :comments,
      [
        comment_template(item_user)
        | Ecto.assoc(item_user, :comments)
          |> where([c], is_nil(c.comment_id))
          |> apply_filters(
            current_user_id,
            params |> Map.put_new("filter", %{"sort" => "inserted_at:desc"})
          )
          |> Repo.all()
      ]
    )
  end

  def comment_template(%Item{}) do
    %ItemComment{
      id: "{{id}}",
      author_id: "{{author_id}}",
      author: %{
        id: "{{author.id}}",
        image: "{{author.image}}",
        details: %{
          "rating" => %{"score" => "{{author.details.rating.score}}"}
        }
      },
      user_id: "{{user_id}}",
      user: %{
        id: "{{author.id}}",
        image: "{{author.image}}"
      },
      item_id: "{{item_id}}",
      inserted_at: "{{inserted_at}}",
      updated_at: "{{updated_at}}",
      details: %{
        "comment_template_tag_id" => "comment_template",
        "body" => "{{details.body}}"
      }
    }
  end

  def comment_template(%User{}) do
    %UserComment{
      id: "{{id}}",
      author_id: "{{author_id}}",
      author: %{
        id: "{{author.id}}",
        image: "{{author.image}}",
        details: %{
          "rating" => %{"score" => "{{author.details.rating.score}}"}
        }
      },
      user_id: "{{user_id}}",
      user: %{
        id: "{{author.id}}",
        image: "{{author.image}}"
      },
      author_id: "{{author_id}}",
      inserted_at: "{{inserted_at}}",
      updated_at: "{{updated_at}}",
      details: %{
        "comment_template_tag_id" => "comment_template"
      }
    }
  end

  def list_comments(
        module,
        current_user_id,
        params = %{"id" => id, "show_for_comment_id" => comment_id}
      ) do
    module.get!(id)
    |> Ecto.assoc(:comments)
    |> where_comment_id(params, comment_id)
    |> apply_filters(current_user_id, params)
    |> Repo.all()
  end

  def list_comments(module, current_user_id, params = %{"id" => id}) do
    module.get!(id)
    |> Ecto.assoc(:comments)
    |> where([c], is_nil(c.comment_id))
    |> apply_filters(
      current_user_id,
      params |> Map.put_new("filter", %{"sort" => "inserted_at:desc"})
    )
    |> Repo.all()
  end

  def apply_filters(item_user, current_user_id, params) do
    item_user
    |> join(:left, [c], u in assoc(c, :author))
    |> preload([:author])
    |> DefaultFilter.min_author_rating_filter(current_user_id)
    |> DefaultFilter.hide_guests_filter(current_user_id)
    |> DefaultFilter.sort_filter(params)
    |> DefaultFilter.paging_filter(params |> Map.put_new("page-size", "3"))
  end

  def where_comment_id(query, _params, comment_id) do
    query
    |> where(comment_id: ^parse_comment_id(comment_id))
  end

  def parse_comment_id(id) do
    {id, _} = to_string(id) |> Integer.parse()
    id
  end

  def create_item_comment(comment \\ %{}) do
    Multi.new()
    |> update_item_comment_count(comment["item_id"])
    |> Multi.insert(:insert, ItemComment.changeset(%ItemComment{}, comment))
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        {:ok, multi.insert |> Repo.preload(:author)}

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

  defp update_item_comment_count(multi, item_id) do
    multi
    |> Multi.run(:item, fn repo, %{} ->
      {:ok, Items.get_item!(item_id, repo)}
    end)
    |> Multi.run(:calc_item_comment_count, fn repo, %{item: item} ->
      calculate_comment_count(repo, Item, item)
    end)
    |> update_user_comment_count(nil)
  end

  defp update_user_comment_count(multi, user_id) do
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

  defp calculate_comment_count(repo, query, item_or_user) do
    query =
      from u in query,
        where: u.id == ^item_or_user.id,
        update: [
          set: [
            details:
              fragment(
                " jsonb_set(details, '{comments_count}', (COALESCE(details->>'comments_count','0')::decimal + 1)::text::jsonb) "
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
