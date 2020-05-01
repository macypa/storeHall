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
  channel_push_debounced("filter", { data: state.filter_params });
}

$("#form-filter").submit(function (event) {
  event.preventDefault();
});

add_events(".auto-submit-item", "change", function () {
  let form = get_form("#form-filter :input");
  let filter_params = form.serialize();
  channel_push_debounced("filter", { data: filter_params });

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
