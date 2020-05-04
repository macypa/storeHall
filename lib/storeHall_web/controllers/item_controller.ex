defmodule StoreHallWeb.ItemController do
  use StoreHallWeb, :controller

  alias StoreHallWeb.AuthController
  alias StoreHall.Items
  alias StoreHall.Items.Item
  alias StoreHall.Users.Action
  alias StoreHall.Ratings
  alias StoreHall.Comments
  alias StoreHall.Images
  alias StoreHall.EncodeHelper

  plug :check_owner when action in [:edit, :delete]

  def index(conn, _params) do
    items = Items.list_items(conn.params, AuthController.get_logged_user_id(conn))

    filters = Items.item_filters()
    render(conn, :index, items: items, filters: filters)
  end

  def new(conn, _params) do
    changeset = Items.change_item(%Item{})
    filters = Items.item_filters()

    render(conn, :new, changeset: changeset, filters: filters)
  end

  def create(conn, %{"item" => item_params}) do
    case Items.create_item(
           EncodeHelper.decode(item_params)
           |> Map.put("user_id", AuthController.get_logged_user_id(conn))
         ) do
      {:ok, item} ->
        conn
        |> put_flash(:info, Gettext.gettext("Item created successfully."))
        |> redirect(to: Routes.user_item_path(conn, :show, item.user_id, item))

      {:error, %Ecto.Changeset{} = changeset} ->
        filters = Items.item_filters()
        render(conn, :new, changeset: changeset, filters: filters)
    end
  end

  def show(conn, params = %{"id" => id}) do
    logged_user_id = AuthController.get_logged_user_id(conn)

    item =
      Items.get_item_with_reactions!(
        id,
        params |> Map.put("user_id", logged_user_id)
      )
      |> Items.preload_user()
      |> Images.append_images(:image)
      |> Comments.preload_for(logged_user_id, params)
      |> Ratings.preload_for(logged_user_id, params)

    # |> Chats.preload_for(AuthController.get_logged_user_id(conn))

    if item.reaction == nil and logged_user_id != nil do
      Action.init_item_reaction(
        Items.get_item_id(id),
        logged_user_id,
        item.user_id
      )
    end

    render(conn, :show, item: item)
  end

  def edit(conn, %{"id" => id}) do
    item =
      Items.get_item!(id)
      |> Items.preload_user()

    changeset = Items.change_item(item)
    filters = Items.item_filters()
    render(conn, :edit, item: item, changeset: changeset, filters: filters)
  end

  def update(conn, %{"id" => id, "item" => item_params}) do
    item = Items.get_item!(id)

    case Items.update_item(item, EncodeHelper.decode(item_params)) do
      {:ok, item} ->
        conn
        |> put_flash(:info, Gettext.gettext("Item updated successfully."))
        |> redirect(to: Routes.user_item_path(conn, :show, item.user_id, item))

      {:error, %Ecto.Changeset{} = changeset} ->
        filters = Items.item_filters()
        render(conn, :edit, item: item, changeset: changeset, filters: filters)
    end
  end

  def delete(conn, %{"id" => id}) do
    item = Items.get_item!(id)
    {:ok, _item} = Items.delete_item(item)

    conn
    |> put_flash(:info, Gettext.gettext("Item deleted successfully."))
    |> redirect(to: Routes.item_path(conn, :index))
  end

  defp check_owner(conn, _params) do
    %{params: %{"id" => item_id}} = conn
    user_id = Items.get_item!(item_id).user_id

    if AuthController.check_owner?(conn, user_id) do
      conn
    else
      conn
      |> put_flash(:error, Gettext.gettext("You cannot do that"))
      |> redirect(to: Routes.item_path(conn, :index))
      |> halt()
    end
  end
end
