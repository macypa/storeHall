
window.onpopstate = function (event) {
  if (event.state) {
    render(event.state);

    var form = $('#form-filter');
    $.each(event.state.filter_params_array, function(field, value) {
      var input = form.find('[name="' + value.name + '"]');
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

$( "#form-filter" ).submit(function( event ) {
  event.preventDefault();
});

add_events(".auto-submit-item", "change", function() {

  var form = $("#form-filter :input").filter(function() {
                                if (!this.value) {
                                  return false;
                                }
                                if (this.name.includes("filter[price]") && this.value == 0) {
                                  return false;
                                }
                                if (this.name.includes("filter[price][max]") && this.value == 1000) {
                                  return false;
                                }
                                if (this.name.includes("filter[rating][min]") && this.value == 0) {
                                  return false;
                                }
                                if (this.name.includes("filter[rating][max]") && this.value == 100) {
                                  return false;
                                }
                                return true;
                              })
  var filter_params = form.serialize();
  channel.push("filter", { data: filter_params })

  window.history.pushState({filter_params_array: form.serializeArray(), filter_params: filter_params},
  document.title,
  (filter_params == "") ? location.pathname : location.pathname + "?" + filter_params);
});

channel.on("filtered_items", payload => {
  var items_template_source = "{{#each this}}<item>" +
       unescape(document.getElementById("item_template").innerHTML)
       .replace("<div data-img=\"{{#each details.images}}<div data-img='{{this}}'> </div>{{/each}}\"> </div>",
                "{{#each details.images}}<div data-img='{{this}}'> </div>{{/each}}")
       .replace(/{{id}}-name/g, "{{id}}")
       + "</item>{{/each}}";
  var items_template = Handlebars.compile(items_template_source);

  var json_payload = JSON.parse(payload.filtered)
  json_payload.csrf_token = $("meta[name='csrf-token']").attr("content")

  var filtered_items = items_template( json_payload )
  if (payload.filter.indexOf("page=") == -1) {
    document.querySelector("#items-listing").innerHTML =
          document.getElementById("item_template").outerHTML
          + filtered_items;
  } else {
    document.querySelector("#items-listing").insertAdjacentHTML( 'beforeend', filtered_items);
  }
  $('.fotorama').fotorama();
  update_next_page_link(payload);
})

channel.on("filtered_users", payload => {
  var users_template_source = "{{#each this}}<user>" +
       unescape(document.getElementById("user_template").innerHTML)
       .replace("<div data-img=\"{{#each details.images}}<div data-img='{{this}}'> </div>{{/each}}\"> </div>",
                "{{#each details.images}}<div data-img='{{this}}'> </div>{{/each}}") +
       "</user>{{/each}}";
  var users_template = Handlebars.compile(users_template_source);

  var filtered_users = users_template( JSON.parse(payload.filtered) )
  if (payload.filter.indexOf("page=") == -1) {
    document.querySelector("#users-listing").innerHTML =
          document.getElementById("user_template").outerHTML
          + filtered_users;
  } else {
    document.querySelector("#users-listing").insertAdjacentHTML( 'beforeend', filtered_users);
  }
  $('.fotorama').fotorama();
  update_next_page_link(payload);
})
