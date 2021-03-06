function on_mail_events() {
  timeago();
  load_lazy_imgs();
  add_load_more_events();
}
window.add_mail_events = function () {
  add_events("[mail-topic]", "click", function () {
    channel_user_push_debounced(this.getAttribute("mail-topic"), {
      data: this.getAttribute("data"),
    });
  });
};
add_mail_events();

window.update_unread_mail_to_header_notification = function () {
  let mail_content_div = document.querySelector("mail text .content");
  if (mail_content_div) {
    localStorage.removeItem("mail_" + mail_content_div.getAttribute("data"));
  }

  let unread_mails = document.querySelector("#unread_mails");

  for (let i = 0; i < localStorage.length; i++) {
    let key = localStorage.key(i);
    if (key.startsWith("mail_")) {
      let new_mail_html = localStorage.getItem(key);
      unread_mails.insertAdjacentHTML("beforeend", new_mail_html);
    }
  }
  timeago();
};
update_unread_mail_to_header_notification();

channel.on("filtered_users", (payload) => {
  let filtered_users = JSON.parse(payload.filtered);
  credits_per_mail = filtered_users.max_credits;
  document.querySelector("#mail_users_count").value = filtered_users.count;
  document.querySelector("#mail_details_credits").value = credits_per_mail;
  document.querySelector("#mail_details_credits").min = credits_per_mail;
  document.querySelector("#mail_total_cost").value =
    filtered_users.total_cost_credits;
});

window.add_mail_details_credits_events = function () {
  add_events("#mail_details_credits", "change", function () {
    document.querySelector("#mail_total_cost").value =
      document.querySelector("#mail_users_count").value * this.value;
  });
};
add_mail_details_credits_events();

let mails_template_source =
  "{{#each this}}" +
  unescape(document.getElementById("mail_template").innerHTML) +
  "{{/each}}";
let mails_template = Handlebars.compile(mails_template_source);
//import mails_template from "../hbs/mails.hbs"
channel.on("filtered_mails", (payload) => {
  let filtered_mails = mails_template(JSON.parse(payload.filtered));
  if (payload.filter.indexOf("page=") == -1) {
    document.querySelector("mails").innerHTML = filtered_mails;
  } else {
    document
      .querySelector("mails")
      .insertAdjacentHTML("beforeend", filtered_mails);
  }

  on_mail_events();
  update_next_page_link(payload);
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
        mail_form.serialize().includes("mail[details][title") ||
        mail_form.serialize().includes("mail%5Bdetails%5D%5Btitle")
      )
    ) {
      flash_error(this.getAttribute("required"));
    } else {
      if (confirm(this.getAttribute("confirm")) == true) {
        let filter_form = get_form("#form-filter :input");
        let filter_params = filter_form.serialize();

        channel_user_push_debounced(this.getAttribute("marketing-mail-topic"), {
          filter_params: filter_params,
          mail_params: mail_form.serialize(),
        });
      }
    }
  });
};
add_marketing_mail_events();

let mail_template_source = unescape(
  document.getElementById("mail_template").innerHTML
);
let mail_template = Handlebars.compile(mail_template_source);
function on_new_mail_event(payload) {
  let new_mail = JSON.parse(payload.new_mail);
  if (!localStorage.getItem("mail_" + new_mail.id)) {
    let new_mail_html = mail_template(new_mail);

    localStorage.setItem("mail_" + new_mail.id, new_mail_html);

    document
      .querySelector("#unread_mails")
      .insertAdjacentHTML("afterbegin", new_mail_html);

    update_notifications_counter_alert();
  }
}

channel_user.on("new_mail", (payload) => {
  on_new_mail_event(payload);
});

channel_user.on("mail_sent", (payload) => {
  flash_info(payload.message);

  update_session();
  update_balance_credits(
    -parseInt(document.querySelector("#mail_total_cost").value)
  );
});

function update_balance_credits(credits) {
  let current_balance = parseInt(
    document.querySelector("#balance_credits").innerHTML
  );
  document.querySelector("#balance_credits").innerHTML =
    current_balance + credits;
}

channel_user.on("mail_credits_claimed", (payload) => {
  $(".claim_icon[data='" + payload.data + "']").remove();

  localStorage.removeItem("mail_" + payload.data);

  update_session();
  update_balance_credits(
    parseInt(document.querySelector("#credits_for_mail").innerText)
  );
});

$(document).ready(function () {
  if (window.loggedUserId == "") {
    for (let i = 0; i < localStorage.length; i++) {
      let key = localStorage.key(i);
      if (key.startsWith("mail_")) {
        localStorage.removeItem(key);
      }
    }

    document.querySelector("#unread_mails").innerHTML = "";
    update_notifications_counter_alert();
  }
});
