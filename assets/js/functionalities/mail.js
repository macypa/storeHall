channel.on("filtered_users", (payload) => {
  let filtered_users = JSON.parse(payload.filtered);
  credits_per_mail = filtered_users.max_credits;
  document.querySelector("#mail_users_count").value = filtered_users.count;
  document.querySelector("#mail_credits_per_mail").value = credits_per_mail;
  document.querySelector("#mail_total_cost").value =
    credits_per_mail * filtered_users.count;
});

$("#mail_details_content").on("input", function () {
  $("#marketing_mail_preview")[0].innerHTML = sanitize_basic_html(this.value);
});

window.add_marketing_mail_events = function () {
  add_events("[marketing-mail-topic]", "click", function (event) {
    event.preventDefault();

    let mail_form = get_form("#mail_form :input");
    if (
      !(
        mail_form.serialize().includes("mail[details]") ||
        mail_form.serialize().includes("mail%5Bdetails")
      )
    ) {
      flash_error(this.getAttribute("required"));
    } else {
      if (confirm(this.getAttribute("confirm")) == true) {
        let filter_form = get_form("#form-filter :input");
        let filter_params = filter_form.serialize();

        channel_user.push(this.getAttribute("marketing-mail-topic"), {
          filter_params: filter_params,
          mail_params: mail_form.serialize(),
        });
      }
    }
  });
};
add_marketing_mail_events();

function get_mail_template() {
  return Handlebars.compile(
    "<li> \
    <div class='mail'> \
        <div>\
          <div class='name'>{{json from_user_id}}</div>\
          <avatar class='img'><img class='lazy' data-src='{{from_user.image}}'></avatar>\
          <div class='text'>\
            {{json details.title}}\
          </div>\
        </div>\
    </div>\
  </li>"
  );
}

function on_new_mail_event(payload) {
  let new_mail = JSON.parse(payload.new_mail);
  let mail_template = get_mail_template(new_mail);
  let new_mail_html = mail_template(new_mail);

  document
    .querySelector("mails")
    .insertAdjacentHTML("beforeend", new_mail_html);

  update_notifications_counter_alert();
}

channel_user.on("mail_sent", (payload) => {
  flash_info(payload.message);
});

channel_user.on("new_mail", (payload) => {
  on_new_mail_event(payload);
});
