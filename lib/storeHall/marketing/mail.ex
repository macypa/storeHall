defmodule StoreHall.Marketing.Mail do
  use Ecto.Schema
  import Ecto.Changeset

  @doc """
  To send mail fill sent_to_user_ids and unread_by_user_ids with user ids
  To read mail remove from unread_by_user_ids
  To claim credits for mail add to claimed_by_user_ids
  To delete mail move user id from sent_to_user_ids to deleted_by_user_ids
  """
  @derive {Jason.Encoder, only: [:id, :from_user, :details]}
  schema "marketing_mails" do
    belongs_to :from_user, StoreHall.Users.User, type: :string

    field :sent_to_user_ids, {:array, :string}, default: []
    field :unread_by_user_ids, {:array, :string}, default: []
    field :deleted_by_user_ids, {:array, :string}, default: []
    field :claimed_by_user_ids, {:array, :string}, default: []

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
    |> cast(attrs, [
      :unread_by_user_ids,
      :sent_to_user_ids,
      :deleted_by_user_ids,
      :claimed_by_user_ids,
      :from_user_id,
      :details
    ])
    |> validate_required([
      :unread_by_user_ids,
      :sent_to_user_ids,
      :deleted_by_user_ids,
      :claimed_by_user_ids,
      :from_user_id,
      :details
    ])
  end
end
