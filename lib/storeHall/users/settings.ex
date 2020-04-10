defmodule StoreHall.Users.Settings do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, []}
  @derive {Phoenix.Param, key: :id}
  schema "user_settings" do
    field :settings, :map,
      default: %{
        "locale" => "bg",
        "credits" => 0,
        "mail_credits" => 10,
        "cookie_consent" => "agreed",
        "marketing_consent" => "not_agreed",
        "social_buttons" => ["facebook", "pinterest", "copy_link"],
        "filters" => %{
          "show_with_min_rating" => "-10",
          "show_with_max_alerts" => "5",
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
