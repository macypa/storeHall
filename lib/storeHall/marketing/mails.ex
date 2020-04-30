defmodule StoreHall.Marketing.Mails do
  import Ecto.Query, warn: false

  alias StoreHall.Repo
  alias Ecto.Multi

  alias StoreHall.Users
  alias StoreHall.Users.User
  alias StoreHall.Marketing.Mail
  require StoreHallWeb.Gettext
  alias StoreHall.DefaultFilter

  @unread_mails_to_load 2
  def unread_mails_to_load(), do: @unread_mails_to_load

  def list_mails(params, current_user_id \\ nil) do
    apply_filters(params, current_user_id)
  end

  def apply_filters(params, current_user_id) do
    from_user_preload_query = from(u in User) |> Users.add_select_fields_for_preload([])

    Mail
    |> preload(from_user: ^from_user_preload_query)
    |> where([u], fragment("? \\?| ?", u.to_users, ^current_user_id))
    |> DefaultFilter.paging_filter(params, -1)
    |> DefaultFilter.sort_filter(params |> Map.put_new("filter", %{"sort" => "inserted_at:desc"}))
    |> Repo.all()
    |> Users.clean_preloaded_user(:from_user, [:info, :marketing_info])
  end

  def preload_sender(mail) do
    mail
    |> Users.preload_sender(Repo)
  end

  def create_mail(mail \\ %{}) do
    Ecto.Multi.new()
    |> Multi.insert(:insert, Mail.changeset(%Mail{}, mail))
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        {:ok, multi.insert}

      {:error, _op, value, _changes} ->
        {:error, value}
    end
  end

  def remove_user_id_from_mail(%Mail{} = mail, user_id) do
    Multi.new()
    |> Multi.run(:mail, fn repo, %{} ->
      {:ok, repo.get!(Mail, mail.id)}
    end)
    |> Multi.insert_or_update(:update, fn %{mail: mail} ->
      Ecto.Changeset.change(mail, to_users: mail.to_users |> List.delete(user_id))
    end)
    |> Repo.transaction()
  end

  def changeset() do
    Mail.changeset(%Mail{}, %{})
  end
end
