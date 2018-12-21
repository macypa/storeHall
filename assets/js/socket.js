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

// Now that you are connected, you can join channels with a topic:
let channel = socket.channel(decodeURI(window.location.pathname), {})
channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

// channel_push('message:add', "test")
var channel_push = function(topic, data) {
  channel.push(topic, { data: data })
};

var add_events = function(selector, on_event, fun) {
  Array.from(document.querySelectorAll(selector)).forEach(function(element) {
    element.addEventListener(on_event, fun);
  });
};

add_events("[reaction_topic]", "click", function() {
  channel.push(this.getAttribute("reaction_topic"), { data: this.getAttribute("data") })
});

channel.on("update_rating", payload => {
  document.querySelector("#rating_score").innerText = payload.new_rating
  document.querySelector("#rating_count").innerText = parseInt(document.querySelector("#rating_count").innerText) + 1
})

add_events("[comment_topic]", "click", function() {
  var body_field_value = this.parentNode.getElementsByClassName("body")[0].value
  var comment_field_value = JSON.parse(this.parentNode.getElementsByClassName("comment")[0].value)
  comment_field_value.details = {}
  comment_field_value.details.body = body_field_value
  channel.push(this.getAttribute("comment_topic"), { data: comment_field_value })

  show_hide(this.parentNode.getAttribute("id"))
});

channel.on("new_comment", payload => {
  var new_comment_html = payload.new_comment
  var new_comment_node = document.createElement("span")
  new_comment_node.innerHTML = new_comment_html

  if (payload.comment_parent_id == null) {
    document.querySelector("comments").appendChild(new_comment_node)
  } else {
    var comment_parent = document.querySelector("#comment_" + payload.comment_parent_id).parentNode
    if (comment_parent !== null) {
      comment_parent.appendChild(new_comment_node)
    }
  }
})

add_events("[rating_topic]", "click", function() {
  var body_field_value = this.parentNode.getElementsByClassName("body")[0].value
  var scores_field_value = this.parentNode.getElementsByClassName("scores")[0].value
  var rating_field_value = JSON.parse(this.parentNode.getElementsByClassName("rating")[0].value)

  rating_field_value.details = {}
  rating_field_value.details.body = body_field_value
  rating_field_value.details.scores = JSON.parse(scores_field_value)
  channel.push(this.getAttribute("rating_topic"), { data: rating_field_value })
});

channel.on("new_rating", payload => {
  var new_rating_html = payload.new_rating
  var new_rating_node = document.createElement("span")
  new_rating_node.innerHTML = new_rating_html

  document.querySelector("ratings").appendChild(new_rating_node)
})

channel.on("error", payload => {
  alert(payload.message)
})

export default socket
