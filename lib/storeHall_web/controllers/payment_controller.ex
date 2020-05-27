defmodule StoreHallWeb.PaymentController do
  use StoreHallWeb, :controller

  alias StoreHallWeb.AuthController
  alias StoreHall.EncodeHelper
  alias StoreHall.Payments
  alias StoreHall.Payment

  plug :check_owner when action in [:index, :delete, :show, :new, :create]

  def index(conn, _params) do
    payments = Payments.all_payments(conn.params, AuthController.get_logged_user_id(conn))

    render(conn, :index, payments: payments)
  end

  def show(conn, _params = %{"id" => id}) do
    payment = Payments.get_payment!(id)

    render(conn, :show,
      payment: payment,
      data: Payments.encode_data(payment.invoice, payment.details["amount"])
    )
  end

  def delete(conn, %{"id" => id, "user_id" => user_id}) do
    payment = Payments.get_payment!(id)

    if payment.details["STATUS"] != "waiting" do
      conn
      |> put_flash(:error, Gettext.gettext("You cannot do that"))
      |> redirect(to: Routes.user_payment_path(conn, :index, user_id))
    else
      {:ok, _payment} = Payments.delete_payment(payment)

      conn
      |> put_flash(:info, Gettext.gettext("Payment deleted successfully."))
      |> redirect(to: Routes.user_payment_path(conn, :index, user_id))
    end
  end

  def new(conn, _params) do
    changeset = Payments.change_payment(%Payment{})

    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"payment" => payment_params}) do
    case Payments.create_payment(
           EncodeHelper.decode(payment_params)
           |> Map.put("user_id", AuthController.get_logged_user_id(conn))
         ) do
      {:ok, payment} ->
        conn
        |> redirect(to: Routes.user_payment_path(conn, :show, payment.user_id, payment))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def status(conn, _params = %{"checksum" => checksum, "encoded" => encoded}) do
    case Payments.validate(checksum, encoded) do
      true ->
        Base.decode64!(encoded)
        |> Payments.parse_data()
        |> Payments.update_payment_state()
        |> case do
          {:error, _} ->
            text(conn, Payments.text_response_to_epay(:error))

          payment ->
            text(conn, Payments.text_response_to_epay(:ok, payment.invoice))
        end

      false ->
        text(conn, Payments.text_response_to_epay(:error))
    end
  end

  def thanks(conn, _params) do
    conn
    |> AuthController.update_user_props_in_session()
    |> put_flash(:info, Gettext.gettext("Payment successful"))
    |> redirect(
      to: Routes.user_payment_path(conn, :index, AuthController.get_logged_user_id(conn))
    )
  end

  def cancel(conn, _params) do
    conn
    |> put_flash(:info, Gettext.gettext("Payment is canceled"))
    |> redirect(
      to: Routes.user_payment_path(conn, :index, AuthController.get_logged_user_id(conn))
    )
  end

  def withdraw(conn, _params) do
    render(conn, "withdraw.html")
  end

  defp check_owner(conn, _params) do
    %{params: %{"user_id" => user_id}} = conn

    if AuthController.check_owner?(conn, user_id) do
      conn
    else
      conn
      |> redirect(
        to: Routes.user_payment_path(conn, :index, AuthController.get_logged_user_id(conn))
      )
      |> halt()
    end
  end
end
