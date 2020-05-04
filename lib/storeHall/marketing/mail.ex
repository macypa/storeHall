defmodule StoreHall.Marketing.Mail do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :from_user, :details]}
  schema "marketing_mails" do
    belongs_to :from_user, StoreHall.Users.User, type: :string

    field :to_users, {:array, :string}, default: []

    field :details, :map,
      default: %{
        "credits" => "",
        "type" => "",
        "title" => "",
        "link" => "",
        "content" => ""
      }

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(mail, attrs) do
    mail
    |> cast(attrs, [:to_users, :from_user_id, :details])
    |> validate_required([:to_users, :from_user_id, :details])
  end
end
