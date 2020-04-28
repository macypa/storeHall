window.onpopstate = function (event) {
  if (event.state) {
    render(event.state);

    let form = $("#form-filter");
    $.each(event.state.filter_params_array, function (field, value) {
      let input = form.find('[name="' + value.name + '"]');
      input.val(value.value);

      if (
        input.closest(".tab")[0] &&
        input.closest(".tab")[0].getElementsByClassName("collapsible")[0]
      ) {
        input
          .closest(".tab")[0]
          .getElementsByClassName("collapsible")[0].checked = true;
      }
    });
  }
};
//
// window.history.replaceState({filter_params_array: $("#form-filter").serializeArray(),
//  filter_params: $("#form-filter").serialize()}, document.title, location.pathname + "?" + $("#form-filter").serialize());

function render(state) {
  channel.push("filter", { data: state.filter_params });
}

$("#form-filter").submit(function (event) {
  event.preventDefault();
});

function get_form(css_query) {
  return $(css_query).filter(function () {
    if (!this.value || this.value == "{}" || this.value == "[]") {
      return false;
    }
    return true;
  });
}

add_events(".auto-submit-item", "change", function () {
  let form = get_form("#form-filter :input");
  let filter_params = form.serialize();
  channel.push("filter", { data: filter_params });

  window.history.pushState(
    {
      filter_params_array: form.serializeArray(),
      filter_params: filter_params,
    },
    document.title,
    filter_params == ""
      ? location.pathname
      : location.pathname + "?" + filter_params
  );
});

channel.on("filtered_items", (payload) => {
  let items_template_source =
    "{{#each this}}<item>" +
    unescape(document.getElementById("item_template").innerHTML)
      .replace(
        "<div data-img=\"{{#each details.images}}<div data-img='{{this}}'> </div>{{/each}}\"> </div>",
        "{{#each details.images}}<div data-img='{{this}}'> </div>{{/each}}"
      )
      .replace(/{{id}}-name/g, "{{id}}") +
    "</item>{{/each}}";
  let items_template = Handlebars.compile(items_template_source);

  let json_payload = JSON.parse(payload.filtered);
  json_payload.csrf_token = $("meta[name='csrf-token']").attr("content");

  let filtered_items = items_template(json_payload);
  if (payload.filter.indexOf("page=") == -1) {
    $("#items-listing item").remove();
  }
  document
    .querySelector("#last_listing_item")
    .insertAdjacentHTML("beforebegin", filtered_items);

  $(".fotorama").fotorama();

  update_empty_filter_result();

  format_money();
  update_features_select_options(payload);
  update_next_page_link(payload);
});

function update_empty_filter_result() {
  let rating_form_tag = document.querySelector("item");
  if (rating_form_tag) {
    $("#empty_filter_result").removeClass("active");
    $("#empty_filter_result").addClass("inactive");
  } else {
    $("#empty_filter_result").removeClass("inactive");
    $("#empty_filter_result").addClass("active");
  }
}

function update_features_select_options(payload) {
  let feature_select = document
    .querySelector("#features")
    .parentElement.querySelector("select");
  let options_values = $("#features ~ .tab-content select > option")
    .map(function () {
      return this.value;
    })
    .get();

  for (let key in payload.feature_filters) {
    if (!options_values.includes(key)) {
      feature_select.insertAdjacentHTML(
        "beforeend",
        "<option value=" +
          key +
          "> " +
          payload.feature_filters[key] +
          "</option>"
      );
    }
  }
}

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

channel_user.on("mail_sent", (payload) => {
  flash_info(payload.message);
});
