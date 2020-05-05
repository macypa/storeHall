defmodule StoreHallWeb.MailController do
  use StoreHallWeb, :controller

  alias StoreHallWeb.AuthController
  alias StoreHall.Marketing.Mails
  alias StoreHall.Users

  plug :check_viewer when action in [:show]
  plug :check_owner when action in [:delete]

  def index(conn, _params) do
    mails = Mails.all_mails(conn.params, AuthController.get_logged_user_id(conn))

    render(conn, :index, mails: mails)
  end

  def show(conn, _params = %{"id" => id}) do
    mail =
      Mails.get_mail!(id)
      |> Users.preload_sender()

    render(conn, :show, mail: mail)
  end

  def delete(conn, %{"id" => id}) do
    mail = Mails.get_mail!(id)
    {:ok, _mail} = Mails.delete_mail(mail)

    conn
    |> put_flash(:info, Gettext.gettext("Mail deleted successfully."))
    |> redirect(to: Routes.user_mail_path(conn, :index, mail.from_user))
  end

  defp check_owner(conn, _params) do
    %{params: %{"id" => mail_id}} = conn
    user_id = Mails.get_mail!(mail_id).from_user_id

    if AuthController.check_owner?(conn, user_id) do
      conn
    else
      conn
      |> put_flash(:error, Gettext.gettext("You cannot do that"))
      |> redirect(to: Routes.user_mail_path(conn, :index, user_id))
      |> halt()
    end
  end

  defp check_viewer(conn, _params) do
    %{params: %{"id" => mail_id, "user_id" => user_id}} = conn

    Mails.get_mail(mail_id)
    |> case do
      nil ->
        StoreHallWeb.Redirector.call(conn, to: "/users/#{user_id}/mails")

      mail ->
        to_user_ids = mail.to_users

        logged_user_id = AuthController.get_logged_user_id(conn)

        can_view =
          in_user_ids?(logged_user_id, to_user_ids) or
            AuthController.check_owner?(conn, user_id)

        if can_view do
          conn
        else
          conn
          |> put_flash(:error, Gettext.gettext("You cannot do that"))
          |> redirect(to: Routes.user_mail_path(conn, :index, user_id))
          |> halt()
        end
    end
  end

  defp in_user_ids?(nil, _), do: false
  defp in_user_ids?(_, []), do: false

  defp in_user_ids?(user_id, [head | tail]) do
    case head == user_id do
      true ->
        true

      false ->
        in_user_ids?(user_id, tail)
    end
  end
end
