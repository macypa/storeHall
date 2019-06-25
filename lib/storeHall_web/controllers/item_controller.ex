defmodule StoreHallWeb.ItemController do
  use StoreHallWeb, :controller

  alias StoreHallWeb.AuthController
  alias StoreHall.Items
  alias StoreHall.Chats
  alias StoreHall.Items.Item
  alias StoreHall.Ratings
  alias StoreHall.Comments

  plug :check_owner when action in [:edit, :delete]

  def index(conn, _params) do
    items = Items.list_items(conn.params)
    filters = Items.item_filters()
    render(conn, :index, items: items, filters: filters)
  end

  def new(conn, _params) do
    changeset = Items.change_item(%Item{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"item" => item_params}) do
    case item_params
         |> Map.put("user_id", conn.assigns.logged_user.id)
         # |> put_in([:details, :merchant], conn.assigns.logged_user.id)
         |> put_in(
           ["details"],
           Jason.decode!(get_in(item_params, ["details"]))
         )
         # |> put_in(
         #   ["details", "images"],
         #   Jason.decode!(get_in(item_params, ["details", "images"]))
         # )
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

  def show(conn, params = %{"id" => id}) do
    item =
      Items.get_item!(id)
      |> Comments.preload_for(AuthController.get_user_id_from_conn(conn), params)
      |> Ratings.preload_for(AuthController.get_user_id_from_conn(conn), params)
      |> Chats.preload_for(AuthController.get_user_id_from_conn(conn))

    render(conn, :show, item: item)
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
             ["details"],
             Jason.decode!(get_in(item_params, ["details"]))
           )
           # |> put_in(
           #   ["details", "images"],
           #   Jason.decode!(get_in(item_params, ["details", "images"]))
           # )
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
    user_id = Items.get_item!(item_id).user_id

    if AuthController.check_owner?(conn, user_id) do
      conn
    else
      conn
      |> put_flash(:error, "You cannot do that")
      |> redirect(to: Routes.item_path(conn, :index))
      |> halt()
    end
  end
end
