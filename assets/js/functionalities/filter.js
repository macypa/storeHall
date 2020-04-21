
window.onpopstate = function (event) {
  if (event.state) {
    render(event.state);

    let form = $('#form-filter');
    $.each(event.state.filter_params_array, function (field, value) {
      let input = form.find('[name="' + value.name + '"]');
      input.val(value.value);

      if (input.closest(".tab")[0] && input.closest(".tab")[0].getElementsByClassName("collapsible")[0]) {
        input.closest(".tab")[0].getElementsByClassName("collapsible")[0].checked = true;
      }
    });

  }
}
//
// window.history.replaceState({filter_params_array: $("#form-filter").serializeArray(),
//  filter_params: $("#form-filter").serialize()}, document.title, location.pathname + "?" + $("#form-filter").serialize());

function render(state) {
  channel.push("filter", { data: state.filter_params })
}

$("#form-filter").submit(function (event) {
  event.preventDefault();
});

add_events(".auto-submit-item", "change", function () {

  let form = $("#form-filter :input").filter(function () {
    if (!this.value || this.value == "{}" || this.value == "[]") {
      return false;
    }
    return true;
  })
  let filter_params = form.serialize();
  channel.push("filter", { data: filter_params })

  window.history.pushState({ filter_params_array: form.serializeArray(), filter_params: filter_params },
    document.title,
    (filter_params == "") ? location.pathname : location.pathname + "?" + filter_params);
});

channel.on("filtered_items", payload => {
  let items_template_source = "{{#each this}}<item>" +
    unescape(document.getElementById("item_template").innerHTML)
      .replace("<div data-img=\"{{#each details.images}}<div data-img='{{this}}'> </div>{{/each}}\"> </div>",
        "{{#each details.images}}<div data-img='{{this}}'> </div>{{/each}}")
      .replace(/{{id}}-name/g, "{{id}}")
    + "</item>{{/each}}";
  let items_template = Handlebars.compile(items_template_source);

  let json_payload = JSON.parse(payload.filtered)
  json_payload.csrf_token = $("meta[name='csrf-token']").attr("content")

  let filtered_items = items_template(json_payload)
  if (payload.filter.indexOf("page=") == -1) {
    document.querySelector("#items-listing").innerHTML =
      document.getElementById("item_template").outerHTML
      + filtered_items;
  } else {
    document.querySelector("#items-listing").insertAdjacentHTML('beforeend', filtered_items);
  }
  $('.fotorama').fotorama();

  update_empty_filter_result();
  update_last_listing_item_id();

  format_money();
  update_features_select_options(payload);
  update_next_page_link(payload);
})

function update_empty_filter_result() {
  let rating_form_tag = document.querySelector("item")
  if (rating_form_tag) {
    $('#empty_filter_result').removeClass("active");
    $('#empty_filter_result').addClass("inactive")
  } else {
    $('#empty_filter_result').removeClass("inactive");
    $('#empty_filter_result').addClass("active")
  }
}

function update_last_listing_item_id() {
  let last_listing_item = document.querySelector("#last_listing_item");
  if (last_listing_item) {
    last_listing_item.removeAttribute("id");
  }

  last_listing_item = $("item").last()[0];
  if (last_listing_item) {
    last_listing_item.setAttribute("id", "last_listing_item");
  }
}

function update_features_select_options(payload) {
  let feature_select = document.querySelector("#features").parentElement.querySelector("select");
  let options_values = $('#features ~ .tab-content select > option').map(function () { return this.value; }).get();

  for (let key in payload.feature_filters) {
    if (!options_values.includes(key)) {
      feature_select.insertAdjacentHTML('beforeend', "<option value="
        + key + "> " + payload.feature_filters[key] + "</option>");
    }
  }
}

channel.on("filtered_users", payload => {
  let filtered_users = JSON.parse(payload.filtered);
  document.querySelector("#users-listing").innerHTML = filtered_users;
})
