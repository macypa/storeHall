
channel.on("update_rating", payload => {
  let rating_badge;
  if (payload.for_user_id) {
    rating_badge = $("#rating-score_" + payload.for_user_id);
  } else {
    rating_badge = $("#rating-score_" + parseInt(payload.for_id));
  }
  rating_badge.text(payload.new_rating);
  rating_badge.attr("data-content", payload.new_rating);
  let rating_count = rating_badge.next().find(".review_score_count > span").first();
  rating_count.text(parseInt(rating_count.text()) + 1);

  rating_badge_color();
})

function on_rating_events() {
  timeago();
  load_lazy_imgs();
  add_load_more_events();
  add_rating_events();
  add_reaction_events();
  rating_pros_cons_format();
}


function validate_scores(rating_scores, max) {
  let sum = 0;
  for (let score in rating_scores) {
    sum += Math.abs(rating_scores[score]);
  }
  if (sum > max) {
    return false;
  }

  return true;
}

function add_rating_events() {
  add_events("[rating-topic]", "click", function () {
    let body_field_value = this.parentNode.getElementsByClassName("rating-textarea")[0].value
    let scores_field = this.parentNode.querySelector("input[name]");
    let rating_field_value = JSON.parse(this.parentNode.getElementsByClassName("rating")[0].value)

    rating_field_value.details = {}
    rating_field_value.details.body = body_field_value
    if (scores_field) {
      rating_field_value.details.scores = JSON.parse(scores_field.value)
    }

    let max_scores_sum = this.parentNode.getElementsByClassName("rating-error-msg")[0];
    if (!max_scores_sum || validate_scores(rating_field_value.details.scores, max_scores_sum.getAttribute("max_scores_sum"))) {
      channel.push(this.getAttribute("rating-topic"), { data: rating_field_value })

      this.parentNode.getElementsByClassName("rating-textarea")[0].value = "";
      $(".hidable-form").each(function () {
        $(this).hide();
      });
    } else {
      let error_msg = this.parentNode.getElementsByClassName("rating-error-msg")[0].value
      alert(error_msg);
      check_if_logged();
    }
  });
}
add_rating_events();

channel.on("new_rating", payload => {

  let rating_template_source = "<rating>" +
    unescape(document.getElementById("rating_template").innerHTML)
      .replace(/\{"\w+_template_tag_id":"\w+_template"\}/g, "{{json details}}") +
    "</rating>";
  let rating_template = Handlebars.compile(rating_template_source);

  let new_rating = JSON.parse(payload.new_rating)
  let new_rating_html = rating_template(new_rating)

  let rating_form_tag = document.querySelector("#rating-" + new_rating.id)
  if (rating_form_tag) {
    $(rating_form_tag.parentNode.parentNode).remove();
  }

  if (payload.rating_parent_id == null || payload.rating_parent_id == -1) {
    document.querySelector("ratings").insertAdjacentHTML('afterbegin', new_rating_html)
  } else {
    let rating_parent = document.querySelector("#rating-" + payload.rating_parent_id).parentNode.parentNode
    if (rating_parent !== null) {
      rating_parent.getElementsByTagName("replies")[0].insertAdjacentHTML('beforeend', new_rating_html)
    }
  }

  document.querySelector("#new_notifications").insertAdjacentHTML('beforeend', new_rating_html.replace(/(<actions>(.|\n)*<\/actions>)/m, "").replace(/(<replies>(.|\n)*<\/replies>)/m, ""))
  update_notifications_counter_alert()

  on_rating_events();
})

channel.on("show_for_rating", payload => {

  let ratings_template_source = "{{#each this}}<rating>" +
    unescape(document.getElementById("rating_template").innerHTML)
      .replace(/\{"\w+_template_tag_id":"\w+_template"\}/g, "{{json details}}") +
    "</rating>{{/each}}";
  let ratings_template = Handlebars.compile(ratings_template_source);

  let filtered_ratings = ratings_template(JSON.parse(payload.filtered))
  if (payload.filter.indexOf("show_for_rating_id=") == -1) {
    document.querySelector("ratings").insertAdjacentHTML('beforeend', filtered_ratings);
  } else {
    let rating_id = payload.filter.match("show_for_rating_id=\\d+");
    let link_node = document.getElementById(rating_id)
    link_node.innerHTML = "";
    link_node.parentNode.parentNode.getElementsByTagName("replies")[0].insertAdjacentHTML('beforeend', filtered_ratings);
  }

  on_rating_events();
})

// import ratings_template from "../hbs/ratings.hbs"
channel.on("filtered_ratings", payload => {
  let ratings_template_source = "{{#each this}}<rating>" +
    unescape(document.getElementById("rating_template").innerHTML)
      .replace(/\{"\w+_template_tag_id":"\w+_template"\}/g, "{{json details}}") +
    "</rating>{{/each}}";
  let ratings_template = Handlebars.compile(ratings_template_source);

  let filtered_ratings = ratings_template(JSON.parse(payload.filtered))
  if (payload.filter.indexOf("page=") == -1) {
    document.querySelector("ratings").innerHTML = filtered_ratings;
  } else {
    document.querySelector("ratings").insertAdjacentHTML('beforeend', filtered_ratings);
  }

  on_rating_events();
  update_next_page_link(payload);
})

window.rating_pros_cons_format = function () {
  $("pro_scores").each(function () {
    if (this.innerText == "") {
      $(this).parent().remove()
    }

    if (!this.innerText.startsWith("{{") && this.innerText.startsWith("{")) {
      let json_data = JSON.parse(this.innerText);
      let html = "";
      for (let score in json_data) {
        if (json_data[score] > 0) {
          html += "<score_text>" + score + ": " + json_data[score] + "</score_text>"
        }
      }

      if (html == "") {
        $(this).parent().remove()
      } else {
        this.innerHTML = html;
      }
    }
  });

  $("con_scores").each(function () {
    if (this.innerText == "") {
      $(this).parent().remove()
    }
    if (!this.innerText.startsWith("{{") && this.innerText.startsWith("{")) {
      let json_data = JSON.parse(this.innerText);
      let html = "";
      for (let score in json_data) {
        if (json_data[score] < 0) {
          html += "<score_text>" + score + ": " + json_data[score] + "</score_text>"
        }
      }

      if (html == "") {
        $(this).parent().remove()
      } else {
        this.innerHTML = html;
      }
    }
  });
};

window.rating_badge_color = function () {
  $(".review_score_badge[data-content]").each(function () {
    let rating = parseInt($(this).attr("data-content"));

    if (rating < -10) {
      $(this).addClass("bg_red");
      // rating_title.text(Bad);
    } else if (rating > 1000) {
      $(this).addClass("bg_blue");
      // rating_title.text(Good);
    } else if (rating > 100) {
      $(this).addClass("bg_green");
      // rating_title.text(Good);
    } else if (rating >= -10) {
      $(this).addClass("bg_orange");
      // rating_title.text(Good);
    }
  });
};

$(document).ready(function () {
  rating_pros_cons_format();
  rating_badge_color();
});
