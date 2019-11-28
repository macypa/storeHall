
channel.on("update_rating", payload => {
  document.querySelector("#rating-score").innerText = payload.new_rating
  document.querySelector("#rating-count").innerText = parseInt(document.querySelector("#rating-count").innerText) + 1
})


function add_rating_events() {
  add_events("[rating-topic]", "click", function() {
    var body_field_value = this.parentNode.getElementsByClassName("body")[0].value
    var scores_field_value = this.parentNode.getElementsByClassName("scores")[0].value
    var rating_field_value = JSON.parse(this.parentNode.getElementsByClassName("rating")[0].value)

    rating_field_value.details = {}
    rating_field_value.details.body = body_field_value
    rating_field_value.details.scores = JSON.parse(scores_field_value)
    channel.push(this.getAttribute("rating-topic"), { data: rating_field_value })
  });
}
add_rating_events();

//import rating_template from "../hbs/rating.hbs"
channel.on("new_rating", payload => {

  var rating_template_source = "<rating>" +
       unescape(document.getElementById("rating_template").innerHTML)
       .replace(/\{"\w+_template_tag_id":"\w+_template"\}/g, "{{json details}}") +
       "</rating>";
  var rating_template = Handlebars.compile(rating_template_source);

  var new_rating_html = rating_template( JSON.parse(payload.new_rating) )

  document.querySelector("ratings").insertAdjacentHTML( 'beforeend', new_rating_html);
  add_rating_events();
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
  load_lazy_imgs();
  update_next_page_link(payload.filter);
})
