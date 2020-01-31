defmodule StoreHall.Users.Settings do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, []}
  @derive {Phoenix.Param, key: :id}
  schema "user_settings" do
    field :settings, :map,
      default: %{
        "locale" => "bg",
        "cookie_consent" => "not_agreed",
        "labels" => %{"liked" => 0, "interested" => 0, "got" => 0, "wish" => 0},
        "relations" => %{"friends" => 0, "favorite" => 0},
        "filters" => %{
          "show_with_min_rating" => "",
          "show_with_max_alerts" => "",
          "hide_guests" => false
        }
      }

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(settings, attrs) do
    settings
    |> cast(attrs, [:settings])
    |> validate_required([:settings])
  end
end
