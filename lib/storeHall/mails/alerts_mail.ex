defmodule StoreHall.AlertsMail do
  import Swoosh.Email
  alias StoreHall.Mailer

  alias StoreHall.Reactions

  def new_mail(user, subject, html_body) do
    new()
    |> to({user.name, user.email})
    |> from({user.name, user.email})
    |> subject(subject)
    |> html_body(html_body)
  end

  def check_alerts() do
    reactions = Reactions.list_alert_reactions()

    if !Enum.empty?(reactions) do
      new_mail(
        Application.get_env(:storeHall, :about)[:user],
        "alert report",
        Phoenix.View.render_to_string(StoreHallWeb.MailView, "items_with_alerts.html", %{
          reactions: reactions
        })
      )
      |> Mailer.deliver()
    end
  end
end
