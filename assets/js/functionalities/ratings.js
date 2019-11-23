
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
