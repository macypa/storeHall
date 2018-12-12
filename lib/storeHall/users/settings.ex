defmodule StoreHall.Users.Settings do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, []}
  @derive {Phoenix.Param, key: :id}
  schema "user_settings" do
    field :settings, :map,
      default: %{
        "labels" => %{"liked" => 0, "interesed" => 0, "got" => 0, "wish" => 0},
        "relations" => %{"friends" => 0, "favorite" => 0}
      }

    timestamps()
  end

  @doc false
  def changeset(settings, attrs) do
    settings
    |> cast(attrs, [:settings])
    |> validate_required([:settings])
  end
end
