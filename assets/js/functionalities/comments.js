function on_comment_events() {
  timeago();
  load_lazy_imgs();
  add_load_more_events();
  add_comment_events();
  add_reaction_events();
}

function add_comment_events() {
  add_events("[comment-topic]", "click", function () {
    let body_field_value = this.parentNode.getElementsByClassName(
      "comment-textarea"
    )[0].value;
    let comment_field_value = JSON.parse(
      this.parentNode.getElementsByClassName("comment")[0].value
    );
    comment_field_value.details = {};
    comment_field_value.details.body = body_field_value;
    channel_push_debounced(this.getAttribute("comment-topic"), {
      data: comment_field_value,
    });

    this.parentNode.getElementsByClassName("comment-textarea")[0].value = "";
    $(".hidable-form").each(function () {
      $(this).hide();
    });
  });
}
add_comment_events();

let comment_template_source = unescape(
  document.getElementById("comment_template").innerHTML
);
let comment_template = Handlebars.compile(comment_template_source);
//import comment_template from "../hbs/comment.hbs"
channel.on("new_comment", (payload) => {
  let new_comment = JSON.parse(payload.new_comment);
  let new_comment_html = comment_template(new_comment);

  if (payload.comment_parent_id == null) {
    document
      .querySelector("comments")
      .insertAdjacentHTML("afterbegin", new_comment_html);
  } else {
    let comment_parent = document.querySelector(
      "#comment-" + payload.comment_parent_id
    );
    if (comment_parent !== null) {
      comment_parent.parentNode.parentNode
        .getElementsByTagName("replies")[0]
        .insertAdjacentHTML("beforeend", new_comment_html);
    }
  }

  if (window.loggedUserId != new_comment.author_id) {
    document
      .querySelector("#new_notifications")
      .insertAdjacentHTML(
        "beforeend",
        new_comment_html
          .replace(/(<actions>(.|\n)*<\/actions>)/m, "")
          .replace(/(<replies>(.|\n)*<\/replies>)/m, "")
      );
    update_notifications_counter_alert();
  }

  on_comment_events();
});

let comments_template_source =
  "{{#each this}}" +
  unescape(document.getElementById("comment_template").innerHTML) +
  "{{/each}}";
let comments_template = Handlebars.compile(comments_template_source);

channel.on("show_for_comment", (payload) => {
  let filtered_comments = comments_template(JSON.parse(payload.filtered));
  if (payload.filter.indexOf("show_for_comment_id=") == -1) {
    document
      .querySelector("comments")
      .insertAdjacentHTML("beforeend", filtered_comments);
  } else {
    let comment_id = payload.filter.match("show_for_comment_id=\\d+");
    let link_node = document.getElementById(comment_id);
    link_node.innerHTML = "";
    link_node.parentNode.parentNode
      .getElementsByTagName("replies")[0]
      .insertAdjacentHTML("beforeend", filtered_comments);
  }

  on_comment_events();
});

//import comments_template from "../hbs/comments.hbs"
channel.on("filtered_comments", (payload) => {
  let filtered_comments = comments_template(JSON.parse(payload.filtered));
  if (payload.filter.indexOf("page=") == -1) {
    document.querySelector("comments").innerHTML = filtered_comments;
  } else {
    document
      .querySelector("comments")
      .insertAdjacentHTML("beforeend", filtered_comments);
  }

  on_comment_events();
  update_next_page_link(payload);
});
