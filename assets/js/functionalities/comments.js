
function add_comment_events() {
  add_events("[comment-topic]", "click", function() {
    var body_field_value = this.parentNode.getElementsByClassName("body")[0].value
    var comment_field_value = JSON.parse(this.parentNode.getElementsByClassName("comment")[0].value)
    comment_field_value.details = {}
    comment_field_value.details.body = body_field_value
    channel.push(this.getAttribute("comment-topic"), { data: comment_field_value })

    show_hide(this.parentNode.getAttribute("id"))
  });
}
add_comment_events();

//import comment_template from "../hbs/comment.hbs"
channel.on("new_comment", payload => {

  var comment_template_source = "<comment>" +
       unescape(document.getElementById("comment_template").innerHTML)
       .replace(/\{"\w+_template_tag_id":"\w+_template"\}/g, "{{json details}}") +
       "</comment>";
  var comment_template = Handlebars.compile(comment_template_source);

  var new_comment_html = comment_template( JSON.parse(payload.new_comment) )

  if (payload.comment_parent_id == null) {
    document.querySelector("comments").insertAdjacentHTML( 'beforeend', new_comment_html)
  } else {
    var comment_parent = document.querySelector("#comment-" + payload.comment_parent_id).parentNode
    if (comment_parent !== null) {
      comment_parent.insertAdjacentHTML( 'beforeend', new_comment_html)
    }
  }

  document.querySelector("#new_notifications").insertAdjacentHTML( 'beforeend', new_comment_html )
  update_notifications_counter_alert()

  timeago();
  add_comment_events();
})
