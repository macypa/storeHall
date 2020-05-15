defmodule StoreHall.Marketing.Mails do
  import Ecto.Query, warn: false

  require StoreHallWeb.Gettext
  alias StoreHallWeb.Gettext, as: Gettext
  alias StoreHall.Repo
  alias Ecto.Multi

  alias StoreHall.Users
  alias StoreHall.Users.User
  alias StoreHall.Users.Settings
  alias StoreHall.Marketing.Mail
  alias StoreHall.DefaultFilter
  alias StoreHall.ParseNumbers

  @unread_mails_to_load 2
  def unread_mails_to_load(), do: @unread_mails_to_load

  def get_mail(id, repo \\ Repo) do
    {id, _} = to_string(id) |> Integer.parse()

    Mail |> repo.get(id) |> format_credits()
  end

  def get_mail!(id, repo \\ Repo) do
    {id, _} = to_string(id) |> Integer.parse()

    Mail |> repo.get!(id) |> format_credits()
  end

  def all_mails(params, current_user_id) do
    Mail
    |> where([m], m.from_user_id == ^current_user_id)
    |> or_where([m], fragment("? \\?| ?", m.sent_to_user_ids, [^current_user_id]))
    |> apply_filters(params, current_user_id)
  end

  def list_inbox_mails(params, current_user_id \\ nil) do
    Mail
    |> where([m], fragment("? \\?| ?", m.sent_to_user_ids, [^current_user_id]))
    |> apply_filters(params, current_user_id)
  end

  def list_inbox_mails_for_header_notifications(params, current_user_id \\ nil) do
    params =
      %{"page-size" => unread_mails_to_load(), "filter" => %{"sort" => "credits:desc"}}
      |> Map.merge(params)

    Mail
    |> where([m], fragment("? \\?| ?", m.unread_by_user_ids, [^current_user_id]))
    |> apply_filters(params, current_user_id)
  end

  defp apply_filters(mail_query, params, current_user_id) do
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
        details: %{
          "title" => mail.details["title"],
          "credits" => mail.details["credits"]
        },
        claimed: is_claimed(mail, current_user_id),
        inserted_at: mail.inserted_at,
        updated_at: mail.updated_at,
        from_user: %{
          id: mail.from_user.id,
          name: mail.from_user.name,
          image: mail.from_user.image
        }
      }
      |> format_credits()
    end)
  end

  defp is_claimed(mail, current_user_id) do
    case mail.from_user_id do
      u when u == current_user_id ->
        "claimed"

      _ ->
        mail.claimed_by_user_ids
        |> Enum.find_value("unclaimed", fn x ->
          if x == current_user_id do
            "claimed"
          end
        end)
    end
  end

  def preload_sender(mail) do
    mail
    |> Users.preload_sender(Repo)
  end

  def broadcast_first_unread_mails(logged_user_id) do
    list_inbox_mails_for_header_notifications(
      %{},
      logged_user_id
    )
    |> Enum.each(fn mail ->
      StoreHallWeb.UsersChannel.broadcast_msg!(
        logged_user_id,
        "new_mail",
        %{
          new_mail: Jason.encode!(mail)
        }
      )
    end)
  end

  defp update_credits_balance(multi, user_id, credits_to_add_or_remove) do
    multi
    |> Multi.run(:label_count, fn repo, _ ->
      query =
        from f in Settings,
          where: f.id == ^user_id,
          update: [
            set: [
              settings:
                fragment(
                  " jsonb_set(settings, '{credits}',
                 (COALESCE(settings->>'credits','0')::int + ?)::text::jsonb) ",
                  ^credits_to_add_or_remove
                )
            ]
          ]

      {:ok, repo.update_all(query, [])}
    end)
  end

  def create_mail(mail, logged_user_id, filtered_users) do
    total_cost_credits = get_total_cost_credits(mail, filtered_users)

    Ecto.Multi.new()
    |> Multi.insert(
      :insert,
      Mail.changeset(%Mail{}, format_credits(mail))
    )
    |> Multi.run(:check_balance, fn _, _ ->
      (Users.get_user_with_settings!(logged_user_id).settings["credits"] -
         total_cost_credits)
      |> case do
        x when x < 0 ->
          {:error, Gettext.gettext("insufficient balance")}

        x ->
          {:ok, x}
      end
    end)
    |> update_credits_balance(logged_user_id, -total_cost_credits)
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        {:ok, multi.insert}

      {:error, _op, value, _changes} ->
        {:error, value}
    end
  end

  defp get_total_cost_credits(mail, filtered_users) do
    total_cost_credits = ParseNumbers.parse_number(filtered_users.total_cost_credits) |> round()

    ParseNumbers.parse_number(mail["details"]["credits"])
    |> round()
    |> Kernel.*(filtered_users.count)
    |> max(total_cost_credits)
  end

  defp format_credits(nil), do: nil

  defp format_credits(mail = %{details: %{"credits" => credits}}) do
    put_in(mail.details["credits"], ParseNumbers.parse_number(credits) |> round())
  end

  defp format_credits(mail = %{"details" => %{"credits" => credits}}) do
    put_in(mail["details"]["credits"], ParseNumbers.parse_number(credits) |> round())
  end

  defp format_credits(mail), do: mail

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
        |> update_credits_balance(
          current_user_id,
          ParseNumbers.parse_number(mail.details["credits"])
        )
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
    %{
      id: "{{id}}",
      claimed: "{{claimed}}",
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
