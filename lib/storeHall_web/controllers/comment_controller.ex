defmodule StoreHallWeb.CommentController do
  use StoreHallWeb, :controller

  alias StoreHall.Comments

  def create(conn, %{"item_comment" => comment_params, "item_id" => item_id}) do
    case Comments.create_item_comment(comment_params) do
      {:ok, _comment} ->
        conn
        |> put_flash(:info, "ItemComment created successfully.")
        |> redirect(to: Routes.item_path(conn, :show, item_id))
    end
  end

  def create(conn, %{"user_comment" => comment_params, "user_id" => user_id}) do
    case Comments.create_user_comment(comment_params) do
      {:ok, _comment} ->
        conn
        |> put_flash(:info, "ItemComment created successfully.")
        |> redirect(to: Routes.user_path(conn, :show, user_id))
    end
  end
end
