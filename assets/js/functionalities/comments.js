
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
    var comment_parent = document.querySelector("#comment-" + payload.comment_parent_id).parentNode.parentNode
    if (comment_parent !== null) {
      comment_parent.getElementsByTagName("replies")[0].insertAdjacentHTML( 'beforeend', new_comment_html)
    }
  }

  document.querySelector("#new_notifications").insertAdjacentHTML( 'beforeend', new_comment_html.replace(/(<actions>(.|\n)*<\/actions>)/m, "").replace(/(<replies>(.|\n)*<\/replies>)/m, "") )
  update_notifications_counter_alert()

  timeago();
  load_lazy_imgs();
  add_load_more_events();
  add_comment_events();
})

channel.on("show_more_comments", payload => {

  var comments_template_source = "{{#each this}}<comment>" +
       unescape(document.getElementById("comment_template").innerHTML)
       .replace(/\{"\w+_template_tag_id":"\w+_template"\}/g, "{{json details}}") +
       "</comment>{{/each}}";
  var comments_template = Handlebars.compile(comments_template_source);

  var filtered_comments = comments_template(JSON.parse(payload.filtered) )
  if (payload.filter.indexOf("show_for_comment_id=") == -1) {
    document.querySelector("comments").insertAdjacentHTML( 'beforeend', filtered_comments);
  } else {
    var comment_id = payload.filter.match("show_for_comment_id=\\d+");
    var link_node = document.getElementById(comment_id)
    link_node.innerHTML = "";
    link_node.parentNode.parentNode.getElementsByTagName("replies")[0].insertAdjacentHTML( 'beforeend', filtered_comments);
  }

  timeago();
  load_lazy_imgs();
  add_load_more_events();
  add_comment_events();
})
