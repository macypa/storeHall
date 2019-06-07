// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// To use Phoenix channels, the first step is to import Socket,
// and connect at the socket path in "lib/web/endpoint.ex".
//
// Pass the token on params as below. Or remove it
// from the params if you are not using authentication.
import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: {token: window.userToken}})

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "lib/web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "lib/web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/3" function
// in "lib/web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket, _connect_info) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, connect to the socket:
socket.connect()


var Handlebars = require('handlebars/runtime');
Handlebars.registerHelper('json', function(context) {
    return JSON.stringify(context);
});

var add_events = function(selector, on_event, fun) {
  Array.from(document.querySelectorAll(selector)).forEach(function(element) {
    if (on_event == "click") {
      element.onclick = fun;
    }
    if (on_event == "change") {
      element.onchange = fun;
    }
  });
};

let channel_user = socket.channel(window.loggedUserChannel, {})
channel_user.join()
  .receive("ok", resp => { console.log("Logged user channel joined successfully " + window.loggedUserChannel, resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

// Now that you are connected, you can join channels with a topic:
var channel_topic = decodeURI(window.location.pathname)
let channel = socket.channel(channel_topic, {})
channel.join()
  .receive("ok", resp => { console.log("Joined successfully " + channel_topic, resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })


function add_chat_events() {
  add_events("[msg-topic]", "click", function() {
    var body_field_value = this.parentNode.getElementsByClassName("body")[0].value
    var msg_field_value = JSON.parse(this.parentNode.getElementsByClassName("msg")[0].value)
    msg_field_value.details = {}
    msg_field_value.details.body = body_field_value

    if (channel_user.state == "joined") {
      channel_user.push(this.getAttribute("msg-topic"), { data: msg_field_value})
    } else {
      channel.push(this.getAttribute("msg-topic"), { data: msg_field_value})
    }
  });
}
add_chat_events()

import chat_msg_template from "../hbs/chat.hbs"
function on_new_msg_event(payload) {
  var new_msg = JSON.parse(payload.new_msg)

  if (window.loggedUserId == new_msg.author_id) {
    new_msg.me_you = 'me'
  } else {
    new_msg.me_you = 'you'
  }

  var new_msg_html = chat_msg_template( new_msg )
  document.querySelector("chats").insertAdjacentHTML( 'beforeend', new_msg_html )

  var topic_id = ""
  if (window.loggedUserId == new_msg.user_id) {
    topic_id = topic_id + new_msg.owner_id
  } else {
    topic_id = topic_id + new_msg.user_id
  }

  if (new_msg.item_id) {
    topic_id + "_" + new_msg.item_id
  }
  var topic = document.getElementById(topic_id)
  if (topic) {
    topic.getElementsByTagName("ul")[0].insertAdjacentHTML( 'beforeend', new_msg_html )
  }

  add_chat_events()
}

channel_user.on("new_msg", payload => {on_new_msg_event(payload)})
channel.on("new_msg", payload => {on_new_msg_event(payload)})

channel_user.on("error", payload => {
  alert(payload.message)
})


// channel_push('message:add', "test")
var channel_push = function(topic, data) {
  channel.push(topic, { data: data })
};

add_events("[reaction-topic]", "click", function() {
  channel.push(this.getAttribute("reaction-topic"), { data: this.getAttribute("data") })
});

channel.on("update_rating", payload => {
  document.querySelector("#rating-score").innerText = payload.new_rating
  document.querySelector("#rating-count").innerText = parseInt(document.querySelector("#rating-count").innerText) + 1
})

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

import comment_template from "../hbs/comment.hbs"
channel.on("new_comment", payload => {
  var new_comment_html = comment_template( JSON.parse(payload.new_comment) )

  if (payload.comment_parent_id == null) {
    document.querySelector("comments").insertAdjacentHTML( 'beforeend', new_comment_html)
  } else {
    var comment_parent = document.querySelector("#comment-" + payload.comment_parent_id).parentNode
    if (comment_parent !== null) {
      comment_parent.insertAdjacentHTML( 'beforeend', new_comment_html)
    }
  }
  add_comment_events();
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

import rating_template from "../hbs/rating.hbs"
channel.on("new_rating", payload => {
  var new_rating_html = rating_template( JSON.parse(payload.new_rating) )

  document.querySelector("ratings").insertAdjacentHTML( 'beforeend', new_rating_html);
  add_rating_events();
})

import * as $ from 'jquery';

window.onpopstate = function (event) {
  if (event.state) {
    render(event.state);

    var form = $('#form-filter');
    $.each(event.state.filter_params_array, function(field, value) {
        form.find('[name="' + value.name + '"]').val(value.value);
    });

  }
}
//
// window.history.replaceState({filter_params_array: $("#form-filter").serializeArray(),
//  filter_params: $("#form-filter").serialize()}, document.title, location.pathname + "?" + $("#form-filter").serialize());

function render(state) {
  channel.push("filter", { data: state.filter_params })
}

add_events(".auto-submit-item", "change", function() {
  var filter_params = $("#form-filter").serialize();
  channel.push("filter", { data: filter_params })

  window.history.pushState({filter_params_array: $("#form-filter").serializeArray(), filter_params: filter_params},
  document.title,
  (filter_params == "") ? location.pathname : location.pathname + "?" + filter_params);
  update_next_page_link(filter_params);
});

$('#next-page-link').on('click', e => {
  var next_page = e.target.href.slice(e.target.href.indexOf('?') + 1);
  channel.push("filter", { data: next_page })
  e.preventDefault();
});

function update_next_page_link(filter_params) {
  filter_params = (filter_params.indexOf("page=") == -1) ? location.pathname + "?" + filter_params + "&page=1" : location.pathname + "?" + filter_params;

  $('#next-page-link').attr('href', filter_params.replace(/page=\d+/, function(page_param) {
    return page_param.replace(/\d+/, function(n) {
      return ++n;
    })
  }));
}

import items_template from "../hbs/items.hbs"
channel.on("filtered_items", payload => {
  var json_payload = JSON.parse(payload.filtered)
  json_payload.csrf_token = $("meta[name='csrf-token']").attr("content")

  var filtered_items = items_template( json_payload )
  if (payload.filter.indexOf("page=") == -1) {
    document.querySelector("#items-listing").innerHTML = filtered_items;
  } else {
    document.querySelector("#items-listing").insertAdjacentHTML( 'beforeend', filtered_items);
  }
  update_next_page_link(payload.filter);
})

import users_template from "../hbs/users.hbs"
channel.on("filtered_users", payload => {
  var filtered_users = users_template( JSON.parse(payload.filtered) )
  if (payload.filter.indexOf("page=") == -1) {
    document.querySelector("#users-listing").innerHTML = filtered_users;
  } else {
    document.querySelector("#users-listing").insertAdjacentHTML( 'beforeend', filtered_users);
  }
  update_next_page_link(payload.filter);
})

channel.on("error", payload => {
  alert(payload.message)
})

export default socket
