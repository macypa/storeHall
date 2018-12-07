defmodule StoreHallWeb.CommentController do
  use StoreHallWeb, :controller

  alias StoreHall.Items
  alias StoreHall.Comments
  alias StoreHall.Comments.Comment

  def index(conn, _params) do
    comments = Comments.list_comments()
    comment_changeset = Comments.change_comment(%Comment{})
    render(conn, "index.html", comments: comments, comment_changeset: comment_changeset)
  end

  def create(conn, %{"comment" => comment_params, "item_id" => item_id}) do
    case Comments.create_comment(comment_params) do
      {:ok, _comment} ->
        conn
        |> put_flash(:info, "Comment created successfully.")
        |> redirect(to: Routes.item_path(conn, :show, item_id))

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Comment not created.")
        |> redirect(to: Routes.item_path(conn, :show, item_id))
    end
  end
end
