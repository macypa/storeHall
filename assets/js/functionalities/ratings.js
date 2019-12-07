
channel.on("update_rating", payload => {
  document.querySelector("#rating-score").innerText = payload.new_rating
  document.querySelector("#rating-count").innerText = parseInt(document.querySelector("#rating-count").innerText) + 1
})

function on_rating_events() {
  timeago();
  load_lazy_imgs();
  add_load_more_events();
  add_rating_events();
  add_reaction_events();
}


function validate_scores(rating_scores, max) {
  var sum = 0;
  for(var score in rating_scores) {
    sum += Math.abs(rating_scores[score]);
  }
  if (sum > max) {
    return false;
  }

  return true;
}

function add_rating_events() {
  add_events("[rating-topic]", "click", function() {
    var body_field_value = this.parentNode.getElementsByClassName("rating-textarea")[0].value
    var scores_field = this.parentNode.getElementsByClassName("scores");
    var rating_field_value = JSON.parse(this.parentNode.getElementsByClassName("rating")[0].value)

    rating_field_value.details = {}
    rating_field_value.details.body = body_field_value
    if (scores_field[0]) {
      rating_field_value.details.scores = JSON.parse(scores_field[0].value)
    }

    var max_scores_sum = this.parentNode.getElementsByClassName("rating-error-msg")[0].getAttribute("max_scores_sum");
    if (validate_scores(rating_field_value.details.scores, max_scores_sum)) {
      channel.push(this.getAttribute("rating-topic"), { data: rating_field_value })

      this.parentNode.getElementsByClassName("rating-textarea")[0].value = "";
      $(".hidable-form").each(function(  ) {
        $(this).hide();
      });
    } else {
      var error_msg = this.parentNode.getElementsByClassName("rating-error-msg")[0].value
      alert(error_msg);
    }
  });
}
add_rating_events();

channel.on("new_rating", payload => {

  var rating_template_source = "<rating>" +
       unescape(document.getElementById("rating_template").innerHTML)
       .replace(/\{"\w+_template_tag_id":"\w+_template"\}/g, "{{json details}}") +
       "</rating>";
  var rating_template = Handlebars.compile(rating_template_source);

  var new_rating_html = rating_template( JSON.parse(payload.new_rating) )

  if (payload.rating_parent_id == null || payload.rating_parent_id == -1) {
    document.querySelector("ratings").insertAdjacentHTML( 'afterbegin', new_rating_html)
  } else {
    var rating_parent = document.querySelector("#rating-" + payload.rating_parent_id).parentNode.parentNode
    if (rating_parent !== null) {
      rating_parent.getElementsByTagName("replies")[0].insertAdjacentHTML( 'beforeend', new_rating_html)
    }
  }

  document.querySelector("#new_notifications").insertAdjacentHTML( 'beforeend', new_rating_html.replace(/(<actions>(.|\n)*<\/actions>)/m, "").replace(/(<replies>(.|\n)*<\/replies>)/m, "") )
  update_notifications_counter_alert()

  on_rating_events();
})

channel.on("show_for_rating", payload => {

  var ratings_template_source = "{{#each this}}<rating>" +
       unescape(document.getElementById("rating_template").innerHTML)
       .replace(/\{"\w+_template_tag_id":"\w+_template"\}/g, "{{json details}}") +
       "</rating>{{/each}}";
  var ratings_template = Handlebars.compile(ratings_template_source);

  var filtered_ratings = ratings_template(JSON.parse(payload.filtered) )
  if (payload.filter.indexOf("show_for_rating_id=") == -1) {
    document.querySelector("ratings").insertAdjacentHTML( 'beforeend', filtered_ratings);
  } else {
    var rating_id = payload.filter.match("show_for_rating_id=\\d+");
    var link_node = document.getElementById(rating_id)
    link_node.innerHTML = "";
    link_node.parentNode.parentNode.getElementsByTagName("replies")[0].insertAdjacentHTML( 'beforeend', filtered_ratings);
  }

  on_rating_events();
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

  on_rating_events();
  update_next_page_link(payload);
})
