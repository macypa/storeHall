defmodule StoreHall.Items.Item do
  use Ecto.Schema
  use Filterable.Phoenix.Model

  import Ecto.Changeset
  import StoreHall.ItemFilterable
  import StoreHall.DefaultFilterable
  import Ecto.Query, warn: false

  filterable do
    paginateable(per_page: 10)

    @options param: :q
    filter search(query, search_terms, conn) do
      search_filter(query, search_terms, conn)
    end

    @options default: "id:desc"
    filter sort(query, value, conn) do
      sort_filter(query, value, conn)
    end
  end

  schema "items" do
    field :name, :string
    field :user_id, :string

    field :details, :map,
      default: %{"tags" => [], "rating" => %{"count" => 0, "score" => -1}, "comments_count" => 0}

    timestamps()
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:name, :user_id, :details])
    |> validate_required([:name, :user_id, :details])
    |> unique_constraint(:not_unique_name_for_user, name: :unique_name_for_user)
  end
end
