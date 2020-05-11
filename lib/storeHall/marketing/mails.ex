defmodule StoreHall.Marketing.Mails do
  import Ecto.Query, warn: false

  alias StoreHall.Repo
  alias Ecto.Multi
  alias StoreHall.ParseNumbers

  alias StoreHall.Users
  alias StoreHall.Users.User
  alias StoreHall.Marketing.Mail
  require StoreHallWeb.Gettext
  alias StoreHall.DefaultFilter

  @unread_mails_to_load 3
  def unread_mails_to_load(), do: @unread_mails_to_load

  def get_mail(id, repo \\ Repo) do
    {id, _} = to_string(id) |> Integer.parse()

    Mail |> repo.get(id)
  end

  def get_mail!(id, repo \\ Repo) do
    {id, _} = to_string(id) |> Integer.parse()

    Mail |> repo.get!(id)
  end

  def all_mails(params, current_user_id) do
    Mail
    |> where([m], m.from_user_id == ^current_user_id)
    |> or_where([m], fragment("? \\?| ?", m.sent_to_user_ids, [^current_user_id]))
    |> apply_filters(params)
  end

  def list_inbox_mails(params, current_user_id \\ nil) do
    Mail
    |> where([m], fragment("? \\?| ?", m.sent_to_user_ids, [^current_user_id]))
    |> apply_filters(params)
  end

  def list_inbox_mails_for_header_notifications(params, current_user_id \\ nil) do
    params =
      %{"page-size" => unread_mails_to_load(), "filter" => %{"sort" => "credits:desc"}}
      |> Map.merge(params)

    Mail
    |> where([m], fragment("? \\?| ?", m.unread_by_user_ids, [^current_user_id]))
    |> apply_filters(params)
  end

  def apply_filters(mail_query, params) do
    from_user_preload_query = from(u in User) |> Users.add_select_fields_for_preload([])

    mail_query
    |> preload(from_user: ^from_user_preload_query)
    |> DefaultFilter.paging_filter(params)
    |> DefaultFilter.sort_filter(params |> Map.put_new("filter", %{"sort" => "inserted_at:desc"}))
    |> Repo.all()
    |> Users.clean_preloaded_user(:from_user, [:info, :marketing_info])
    |> Enum.map(fn mail ->
      %{
        id: mail.id,
        details: %{"title" => mail.details["title"]},
        inserted_at: mail.inserted_at,
        updated_at: mail.updated_at,
        from_user: %{
          id: mail.from_user.id,
          name: mail.from_user.name,
          image: mail.from_user.image
        }
      }
    end)
  end

  def preload_sender(mail) do
    mail
    |> Users.preload_sender(Repo)
  end

  def create_mail(mail \\ %{}) do
    Ecto.Multi.new()
    |> Multi.insert(:insert, Mail.changeset(%Mail{}, prepare_for_insert(mail)))
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        {:ok, multi.insert}

      {:error, _op, value, _changes} ->
        {:error, value}
    end
  end

  defp prepare_for_insert(mail) do
    mail
    |> ParseNumbers.prepare_number(["details", "credits"])
  end

  def read_mail(mail = %Mail{from_user_id: from_user_id}, current_user_id)
      when from_user_id == current_user_id do
    mail
  end

  def read_mail(%Mail{} = mail, current_user_id) do
    case Enum.member?(mail.unread_by_user_ids, current_user_id) do
      false ->
        mail

      true ->
        Multi.new()
        |> Multi.insert_or_update(:update, fn %{} ->
          Ecto.Changeset.change(mail,
            unread_by_user_ids: mail.unread_by_user_ids |> List.delete(current_user_id)
          )
        end)
        |> Repo.transaction()

        mail
    end
  end

  def claim_mail_credits(%Mail{from_user_id: from_user_id}, current_user_id)
      when from_user_id == current_user_id,
      do: nil

  def claim_mail_credits(%Mail{} = mail, current_user_id) do
    case Enum.member?(mail.claimed_by_user_ids, current_user_id) do
      true ->
        nil

      false ->
        Multi.new()
        |> Multi.insert_or_update(:update, fn %{} ->
          Ecto.Changeset.change(mail,
            claimed_by_user_ids: mail.claimed_by_user_ids ++ [current_user_id]
          )
        end)
        |> Repo.transaction()
    end
  end

  def delete_mail(mail = %Mail{from_user_id: from_user_id}, current_user_id)
      when from_user_id == current_user_id do
    Ecto.Multi.new()
    |> Multi.delete(:delete_mail, mail)
    |> Repo.transaction()
  end

  def delete_mail(%Mail{} = mail, current_user_id) do
    mail
    |> remove_mail_from_user_inbox(current_user_id)
  end

  defp remove_mail_from_user_inbox(%Mail{} = mail, user_id) do
    Multi.new()
    |> Multi.insert_or_update(:update, fn %{} ->
      Ecto.Changeset.change(mail,
        sent_to_user_ids: mail.sent_to_user_ids |> List.delete(user_id),
        deleted_by_user_ids: mail.deleted_by_user_ids ++ [user_id]
      )
    end)
    |> Repo.transaction()
  end

  def mail_template() do
    %Mail{
      id: "{{id}}",
      inserted_at: "{{inserted_at}}",
      updated_at: "{{updated_at}}",
      from_user: %{
        id: "{{from_user.id}}",
        name: "{{from_user.name}}",
        image: "{{from_user.image}}"
      },
      details: %{
        "credits" => "{{json details.credits}}",
        "type" => "{{details.type}}",
        "title" => "{{details.title}}",
        "link" => "{{details.link}}",
        "content" => "{{details.content}}"
      }
    }
  end

  def changeset() do
    Mail.changeset(%Mail{}, %{})
  end
end
