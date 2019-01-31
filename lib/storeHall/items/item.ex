defmodule StoreHall.Items.Item do
  use Ecto.Schema

  import Ecto.Changeset

  @derive {Poison.Encoder, only: [:id, :name, :details, :user_id]}
  schema "items" do
    field :name, :string
    field :user_id, :string

    field :details, :map,
      default: %{
        "tags" => [],
        "images" => [],
        "rating" => %{"count" => 0, "score" => -1},
        "comments_count" => 0
      }

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
