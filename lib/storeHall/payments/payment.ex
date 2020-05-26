defmodule StoreHall.Payment do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :user_id, :invoice, :details, :inserted_at, :updated_at]}
  schema "payments" do
    belongs_to :user, StoreHall.Users.User, type: :string
    field :invoice, :integer

    field :details, :map,
      default: %{
        "credits" => 10,
        "amount" => 0.10,
        "STATUS" => "waiting"
      }

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(payments, attrs) do
    payments
    |> cast(attrs, [:user_id, :invoice, :details])
    |> validate_required([:user_id, :invoice, :details])
    |> unique_constraint(:invoice_exists, name: :unique_invoice)
  end
end
