defmodule StoreHallWeb.ItemController do
  use StoreHallWeb, :controller

  alias StoreHallWeb.AuthController
  alias StoreHall.Items
  alias StoreHall.Items.Item
  alias StoreHall.Ratings
  alias StoreHall.Comments

  plug :check_owner when action in [:edit, :delete]

  def index(conn, _params) do
    items = [
      %Item{
        id: "{{id}}",
        name: "{{name}}",
        user_id: "{{user_id}}",
        inserted_at: "{{inserted_at}}",
        updated_at: "{{updated_at}}",
        alertz_count: "{{alertz_count}}",
        lolz_count: "{{lolz_count}}",
        wowz_count: "{{wowz_count}}",
        mehz_count: "{{mehz_count}}",
        reaction: %{
          reaction: "{{reaction.reaction}}"
        },
        details: %{
          "item_template_tag_id" => "item_template",
          "price" => "{{json details.price}}",
          "images" => ["{{#each details.images}}<a href='{{this}}'></a>{{/each}}"],
          "rating" => %{"score" => "{{json details.rating.score}}"},
          "comments_count" => "{{json details.comments_count}}"
        }
      }
      | Items.list_items(conn.params)
    ]

    filters = Items.item_filters()
    render(conn, :index, items: items, filters: filters)
  end

  def new(conn, _params) do
    changeset = Items.change_item(%Item{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"item" => item_params}) do
    case Items.create_item(
           Items.decode_params(item_params)
           |> Map.put("user_id", AuthController.get_user_id_from_conn(conn))
         ) do
      {:ok, item} ->
        conn
        |> put_flash(:info, Gettext.gettext("Item created successfully."))
        |> redirect(to: Routes.item_path(conn, :show, item))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, params = %{"id" => id}) do
    item =
      Items.get_item_with_reactions!(
        id,
        params |> Map.put("user_id", AuthController.get_user_id_from_conn(conn))
      )
      |> Items.preload_user()
      |> Comments.preload_for(AuthController.get_user_id_from_conn(conn), params)
      |> Ratings.preload_for(AuthController.get_user_id_from_conn(conn), params)

    # |> Chats.preload_for(AuthController.get_user_id_from_conn(conn))

    render(conn, :show, item: item)
  end

  def edit(conn, %{"id" => id}) do
    item = Items.get_item!(id)
    changeset = Items.change_item(item)
    render(conn, :edit, item: item, changeset: changeset)
  end

  def update(conn, %{"id" => id, "item" => item_params}) do
    item = Items.get_item!(id)

    case Items.update_item(item, Items.decode_params(item_params)) do
      {:ok, item} ->
        conn
        |> put_flash(:info, Gettext.gettext("Item updated successfully."))
        |> redirect(to: Routes.item_path(conn, :show, item))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, item: item, changeset: changeset)
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
