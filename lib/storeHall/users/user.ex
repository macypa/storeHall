defmodule StoreHall.Users.User do
  use Ecto.Schema
  use Filterable.Phoenix.Model

  import Ecto.Changeset
  import StoreHall.UserFilterable
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

  @primary_key {:id, :string, []}
  @derive {Phoenix.Param, key: :id}
  schema "users" do
    field :email, :string, unique: true
    field :first_name, :string
    field :last_name, :string
    field :image, :string, default: ""
    field :provider, :string

    field :details, :map,
      default: %{"rating" => %{"count" => 0, "score" => -1}, "comments_count" => 0}

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :email, :image, :provider, :details])
    |> validate_required([:first_name, :email, :provider, :details])
    |> unique_constraint(:email)
  end
end
