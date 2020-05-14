defmodule StoreHall.Plugs.SetUser do
  import Plug.Conn
  alias StoreHallWeb.AuthController
  alias StoreHall.Users
  alias StoreHall.Marketing.Mails

  def init(_params) do
  end

  def call(conn, params) do
    case AuthController.get_logged_user_id(conn) do
      nil ->
        conn
        |> assign(:user_token, "guest")

      user_id ->
        token = Phoenix.Token.sign(conn, "user token", user_id)

        set_locale(get_session(conn, :logged_user_settings), params)

        conn
        |> update_marketing_info()
        |> fetch_first_unread_mails()
        # |> assign(:logged_user_id, user_id)
        |> assign(:user_token, token)
        |> StoreHallWeb.CookieConsentController.set_cookie_consent(user_id)
    end
  end

  defp update_marketing_info(conn) do
    case get_session(conn, :logged_user_marketing_info)["marketing_consent"] do
      "agreed" ->
        update_marketing_last_activity(
          conn,
          get_session(conn, :logged_user_marketing_info)["last_activity"]
        )

      _ ->
        conn
    end
  end

  @one_minute 60
  defp fetch_first_unread_mails(conn) do
    logged_user_id = get_session(conn, :logged_user_id)
    last_mail_check = get_session(conn, :last_mail_check) || DateTime.from_unix!(0)
    time_threshold = DateTime.utc_now() |> DateTime.add(-@one_minute)

    case DateTime.compare(last_mail_check, time_threshold) do
      :lt ->
        conn
        |> fetch_first_unread_mails(logged_user_id)

      _ ->
        conn
    end
  end

  def fetch_first_unread_mails(conn, logged_user_id) do
    conn
    |> put_session(
      :logged_user_unread_mail,
      Mails.list_inbox_mails_for_header_notifications(
        %{},
        logged_user_id
      )
    )
    |> put_session(:last_mail_check, DateTime.utc_now())
  end

  def update_marketing_last_activity(conn, 0), do: update_marketing_last_activity(conn)
  def update_marketing_last_activity(conn, nil), do: update_marketing_last_activity(conn)

  @one_day 60 * 60 * 24
  def update_marketing_last_activity(conn, last_activity) do
    date_threshold = DateTime.utc_now() |> DateTime.add(-@one_day)
    {:ok, last_activity, 0} = DateTime.from_iso8601(last_activity)

    case DateTime.compare(last_activity, date_threshold) do
      :lt -> update_marketing_last_activity(conn)
      _ -> conn
    end
  end

  def update_marketing_last_activity(conn) do
    get_session(conn, :logged_user_id)
    |> Users.get_user!([:marketing_info])
    |> Users.update_user(%{
      "marketing_info" => %{"last_activity" => DateTime.utc_now()}
    })

    conn
    |> put_session(
      :logged_user_marketing_info,
      get_session(conn, :logged_user_marketing_info)
      |> Map.put("last_activity", DateTime.to_iso8601(DateTime.utc_now()))
    )
  end

  def(set_locale(user_settings), do: set_locale(user_settings, nil))

  def set_locale(_user_settings, params = %{"locale" => _lang}) do
    set_locale(params, nil)
  end

  def set_locale(nil, _params), do: nil

  def set_locale(user_settings, _params) do
    if Map.has_key?(user_settings, "locale") do
      StoreHallWeb.Gettext |> Gettext.put_locale(user_settings["locale"])
    end
  end
end
