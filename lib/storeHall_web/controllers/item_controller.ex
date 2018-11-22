defmodule StoreHallWeb.ItemController do
  use StoreHallWeb, :controller

  alias StoreHall.Items
  alias StoreHall.Items.Item

  plug :check_owner when action in [:edit, :delete]

  def index(conn, _params) do
    items = Items.list_items()
    render(conn, :index, items: items)
  end

  def new(conn, _params) do
    changeset = Items.change_item(%Item{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"item" => item_params}) do
    case item_params
         |> Map.put("user_id", conn.assigns.user.id)
         |> Map.put("details", StoreHall.EncodeHelper.decode(item_params, "details"))
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
    render(conn, :show, item: item)
  end

  def edit(conn, %{"id" => id}) do
    item = Items.get_item!(id)
    changeset = Items.change_item(item)
    render(conn, :edit, item: item, changeset: changeset)
  end

  def update(conn, %{"id" => id, "item" => item_params}) do
    item = Items.get_item!(id)

    case Items.update_item(item, item_params) do
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
