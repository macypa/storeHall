
window.onpopstate = function (event) {
  if (event.state) {
    render(event.state);

    var form = $('#form-filter');
    $.each(event.state.filter_params_array, function(field, value) {
      var input = form.find('[name="' + value.name + '"]');
        input.val(value.value);

        if (input.closest(".tab")[0].getElementsByClassName("collapsible")[0]) {
          input.closest(".tab")[0].getElementsByClassName("collapsible")[0].checked = true;
        } else {
          input.closest(".tab")[0].getElementsByClassName("collapsible")[0].checked = false;
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
  update_next_page_link(filter_params);
});

channel.on("filtered_items", payload => {
  if (payload.filtered != "[]") {
    var items_template_source = "{{#each this}}<item>" +
         unescape(document.getElementById("item_template").innerHTML).replace(/{{id}}-name/g, "{{id}}") +
         "</item>{{/each}}";
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
    update_next_page_link(payload.filter);

    $('#next-page-link')[0].removeAttribute("disabled");
    $('.lazy').Lazy({visibleOnly: true});
  } else {
    $('#next-page-link')[0].setAttribute("disabled", "disabled");
  }
})

channel.on("filtered_users", payload => {

  var users_template_source = "{{#each this}}<user>" +
       unescape(document.getElementById("user_template").innerHTML) +
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
  update_next_page_link(payload.filter);
})


// import ratings_template from "../hbs/ratings.hbs"
channel.on("filtered_ratings", payload => {

  var ratings_template_source = "{{#each this}}<rating>" +
       unescape(document.getElementById("rating_template").innerHTML)
       .replace(/\{"\w+_template_tag_id":"\w+_template"\}/g, "{{json details}}") +
       "</rating>{{/each}}";
  var ratings_template = Handlebars.compile(ratings_template_source);

  var filtered_ratings = ratings_template( JSON.parse(payload.filtered) )
  if (payload.filter.indexOf("page=") == -1) {
    document.querySelector("ratings").innerHTML = filtered_ratings;
  } else {
    document.querySelector("ratings").insertAdjacentHTML( 'beforeend', filtered_ratings);
  }
  update_next_page_link(payload.filter);
})

//import comments_template from "../hbs/comments.hbs"
channel.on("filtered_comments", payload => {

  var comments_template_source = "{{#each this}}<comment>" +
       unescape(document.getElementById("comment_template").innerHTML)
       .replace(/\{"\w+_template_tag_id":"\w+_template"\}/g, "{{json details}}") +
       "</comment>{{/each}}";
  var comments_template = Handlebars.compile(comments_template_source);

  var filtered_comments = comments_template( JSON.parse(payload.filtered) )
  if (payload.filter.indexOf("page=") == -1) {
    document.querySelector("comments").innerHTML = filtered_comments;
  } else {
    document.querySelector("comments").insertAdjacentHTML( 'beforeend', filtered_comments);
  }
  $(".timeago").timeago();
  update_next_page_link(payload.filter);
})
