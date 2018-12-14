defmodule StoreHallWeb.ItemController do
  use StoreHallWeb, :controller
  use Rummage.Phoenix.Controller

  alias StoreHall.Items
  alias StoreHall.Items.Item
  alias StoreHall.Comments
  alias StoreHall.Ratings

  plug :check_owner when action in [:edit, :delete]

  def index(conn, params) do
    {items, rummage} = Items.list_items(params)
    filters = Items.item_filters()
    render(conn, :index, items: items, filters: filters, rummage: rummage)
  end

  def new(conn, _params) do
    changeset = Items.change_item(%Item{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"item" => item_params}) do
    case item_params
         |> Map.put("user_id", conn.assigns.user.id)
         # |> put_in([:details, :merchant], conn.assigns.user.id)
         |> put_in(
           ["details", "tags"],
           Poison.decode!(get_in(item_params, ["details", "tags"]))
         )
         # |> Map.put(:details, StoreHall.EncodeHelper.decode(item_params, :details))
         |> Items.create_item() do
      {:ok, item} ->
        conn
        |> put_flash(:info, "Item created successfully.")
        |> redirect(to: Routes.item_path(conn, :show, item))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    item = Items.get_item!(id)

    render(conn, :show,
      item: item,
      comments_info: collect_comments_info(conn, item),
      ratings_info: collect_ratings_info(conn, item)
    )
  end

  def collect_comments_info(conn, item) do
    %{
      comments: Comments.for_item(item.id),
      comment_path: Routes.item_comment_path(conn, :create, item),
      comment_changeset:
        Comments.construct_item_comment(%{
          item_id: item.id,
          author_id: conn.assigns.user.id,
          user_id: item.user_id
        })
    }
  end

  def collect_ratings_info(conn, item) do
    %{
      ratings: Ratings.for_item(item.id),
      rating_path: Routes.item_rating_path(conn, :create, item),
      rating_changeset:
        Ratings.construct_item_rating(%{
          item_id: item.id,
          author_id: conn.assigns.user.id,
          user_id: item.user_id
        })
    }
  end

  def edit(conn, %{"id" => id}) do
    item = Items.get_item!(id)
    changeset = Items.change_item(item)
    render(conn, :edit, item: item, changeset: changeset)
  end

  def update(conn, %{"id" => id, "item" => item_params}) do
    item = Items.get_item!(id)

    case Items.update_item(
           item,
           item_params
           |> put_in(
             ["details", "tags"],
             Poison.decode!(get_in(item_params, ["details", "tags"]))
           )
         ) do
      {:ok, item} ->
        conn
        |> put_flash(:info, "Item updated successfully.")
        |> redirect(to: Routes.item_path(conn, :show, item))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, item: item, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    item = Items.get_item!(id)
    {:ok, _item} = Items.delete_item(item)

    conn
    |> put_flash(:info, "Item deleted successfully.")
    |> redirect(to: Routes.item_path(conn, :index))
  end

  defp check_owner(conn, _params) do
    %{params: %{"id" => item_id}} = conn

    itemUserId = Items.get_item!(item_id).user_id

    if conn.assigns && conn.assigns.user &&
         (itemUserId == conn.assigns.user.id || itemUserId == nil) do
      conn
    else
      conn
      |> put_flash(:error, "You cannot do that")
      |> redirect(to: Routes.item_path(conn, :index))
      |> halt()
    end
  end
end
