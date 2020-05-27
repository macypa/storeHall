defmodule StoreHall.Payments do
  import Ecto.Query, warn: false

  require StoreHallWeb.Gettext
  alias StoreHallWeb.Gettext, as: Gettext

  alias StoreHall.Repo
  alias Ecto.Multi

  alias StoreHall.Users
  alias StoreHall.Users.Settings
  alias StoreHall.Payment
  alias StoreHall.DefaultFilter
  alias StoreHall.ParseNumbers

  def get_payment(id, repo \\ Repo) do
    {id, _} = to_string(id) |> Integer.parse()

    Payment |> repo.get(id)
  end

  def get_payment!(id, repo \\ Repo) do
    {id, _} = to_string(id) |> Integer.parse()

    Payment |> repo.get!(id)
  end

  def get_payment_by_invoice(invoice, repo \\ Repo) do
    {invoice, _} = to_string(invoice) |> Integer.parse()

    Payment |> repo.get_by(invoice: invoice)
  end

  def get_payment_by_invoice!(invoice, repo \\ Repo) do
    {invoice, _} = to_string(invoice) |> Integer.parse()

    Payment |> repo.get_by!(invoice: invoice)
  end

  def all_payments(params, current_user_id) do
    Payment
    |> where([m], m.user_id == ^current_user_id)
    |> apply_filters(params)
  end

  defp apply_filters(payment_query, params) do
    payment_query
    |> DefaultFilter.paging_filter(params)
    |> DefaultFilter.sort_filter(params |> Map.put_new("filter", %{"sort" => "inserted_at:desc"}))
    |> Repo.all()
  end

  def create_payment(payment \\ %{}) do
    Ecto.Multi.new()
    |> Multi.insert(
      :insert,
      Payment.changeset(%Payment{}, prepare_for_insert(payment))
    )
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        {:ok, multi.insert}

      {:error, _op, value, _changes} ->
        {:error, value}
    end
  end

  defp prepare_for_insert(payment) do
    payment
    |> ParseNumbers.prepare_number(["details", "credits"])
    |> ParseNumbers.prepare_number(["details", "amount"])
    |> init_payment
  end

  def delete_payment(%Payment{} = payment) do
    Ecto.Multi.new()
    |> Multi.delete(:delete_payment, payment)
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        {:ok, multi.delete_payment}

      {:error, _op, value, _changes} ->
        {:error, value}
    end
  end

  defp update_payment_state(multi, data = %{"STATUS" => "PAID"}) do
    multi
    |> Multi.run(:user_settings, fn repo, %{payment: payment} ->
      {:ok, Settings |> repo.get!(payment.user_id)}
    end)
    |> Multi.run(:update_settings_credits, fn repo, %{payment: payment} ->
      query =
        Users.construct_update_credits_query(
          payment.user_id,
          payment.details["credits"]
        )

      {:ok, repo.update_all(query, [])}
    end)
    |> Multi.run(:user_settings_after, fn repo, %{payment: payment} ->
      {:ok, Settings |> repo.get!(payment.user_id)}
    end)
    |> Multi.update(:update, fn %{
                                  user_settings: user_settings,
                                  user_settings_after: user_settings_after,
                                  payment: payment
                                } ->
      Payment.changeset(payment, %{
        details:
          payment.details
          |> Map.merge(
            data
            |> Map.put("credits_before", user_settings.settings["credits"])
            |> Map.put("credits_after", user_settings_after.settings["credits"])
          )
      })
    end)
  end

  defp update_payment_state(multi, data) do
    multi
    |> Multi.update(:update, fn %{payment: payment} ->
      Payment.changeset(payment, %{details: payment.details |> Map.merge(data)})
    end)
  end

  def update_payment_state(data) do
    Ecto.Multi.new()
    |> Multi.run(:payment, fn repo, %{} ->
      {:ok,
       data["INVOICE"]
       |> get_payment_by_invoice!(repo)}
    end)
    |> Multi.run(:validate, fn _repo, %{payment: payment} ->
      case payment.details["STATUS"] do
        "waiting" -> {:ok, "status: waiting"}
        _ -> {:error, Gettext.gettext("already received response from epay!")}
      end
    end)
    |> update_payment_state(data)
    |> Repo.transaction()
    |> case do
      {:ok, multi} ->
        multi.update

      {:error, _op, value, _changes} ->
        {:error, value}
    end
  end

  def payment_template() do
    %{
      id: "{{id}}",
      user_id: "{{user_id}}",
      invoice: "{{invoice}}",
      inserted_at: "{{inserted_at}}",
      updated_at: "{{updated_at}}",
      details: %{
        "amount" => "{{json details.amount}}",
        "credits" => "{{json details.credits}}",
        "STATUS" => "{{json details.STATUS}}"
      }
    }
  end

  def change_payment(%Payment{} = payment) do
    Payment.changeset(payment, %{invoice: 0_000_101})
  end

  def changeset() do
    Payment.changeset(%Payment{}, %{})
  end

  @epay_url Application.get_env(:storeHall, :payment)[:epay_url] || ""
  @epay_MIN Application.get_env(:storeHall, :payment)[:epay_MIN] || ""
  @epay_secret_key Application.get_env(:storeHall, :payment)[:epay_secret_key] || ""
  @start_invoice_number Application.get_env(:storeHall, :payment)[:start_invoice_number] ||
                          000_001
  @currency Application.get_env(:storeHall, :payment)[:currency] || "BGN"
  @exp_time_sec_add Application.get_env(:storeHall, :payment)[:exp_time_sec_add] || 0
  @encoding Application.get_env(:storeHall, :payment)[:encoding] || "utf-8"

  defp init_payment(payment) do
    payment
    |> put_in(["invoice"], get_next_invoice_number())
    |> put_in(["details", "amount"], calc_amount_for_credits(payment))
    |> put_in(["details", "STATUS"], "waiting")
  end

  defp get_next_invoice_number() do
    (Repo.one(from x in Payment, select: x.invoice, order_by: [desc: x.invoice], limit: 1) ||
       @start_invoice_number) + 10
  end

  defp calc_amount_for_credits(payment) do
    (payment["details"]["credits"] * 0.01) |> Float.round(2)
  end

  def parse_data(decoded_data) do
    decoded_data
    |> String.replace("\n", "")
    |> String.split(":")
    |> Enum.reduce(%{}, fn x, acc ->
      key_value = x |> String.split("=")
      acc |> Map.put(key_value |> hd(), key_value |> Enum.reverse() |> hd())
    end)
  end

  def text_response_to_epay(:ok, invoice), do: "INVOICE=" <> to_string(invoice) <> ":STATUS=OK"
  def text_response_to_epay(:no, invoice), do: "INVOICE=" <> to_string(invoice) <> ":STATUS=NO"
  def text_response_to_epay(:error), do: "ERR=Not valid CHECKSUM"

  def encode_data(invoice, amount \\ 0.01)

  def encode_data(nil, amount) do
    encode_data(@start_invoice_number, amount)
  end

  def encode_data(invoice, amount) do
    encoded = Base.encode64(epay_invoice_data(invoice, amount))

    %{
      checksum: epay_hmac(encoded),
      encoded: encoded,
      url: @epay_url,
      url_ok_cancel_host: Application.get_env(:storeHall, :about)[:host]
    }
  end

  def validate(checksum, encoded) do
    epay_hmac(encoded) == checksum
  end

  defp epay_hmac(data) do
    :crypto.hmac(:sha, @epay_secret_key, data)
    |> Base.encode16(case: :lower)
    |> String.downcase()
  end

  defp epay_invoice_data(invoice, amount) do
    description = description(amount)
    exp_date = exp_date()

    """
    MIN=#{@epay_MIN}
    INVOICE=#{invoice}
    AMOUNT=#{amount}
    CURRENCY=#{@currency}
    EXP_TIME=#{exp_date}
    ENCODING=#{@encoding}
    DESCR=#{description}
    """
  end

  defp description(amount) do
    "Credits for the amount of #{amount} #{@currency}"
  end

  defp exp_date() do
    today =
      DateTime.utc_now()
      |> DateTime.add(@exp_time_sec_add)

    [today.day, today.month, today.year]
    |> Enum.map(&to_string/1)
    |> Enum.map(&String.pad_leading(&1, 2, "0"))
    |> Enum.join(".")
  end
end
