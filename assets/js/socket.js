// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// To use Phoenix channels, the first step is to import Socket,
// and connect at the socket path in "lib/web/endpoint.ex".
//
// Pass the token on params as below. Or remove it
// from the params if you are not using authentication.
import { Socket } from "phoenix";

let socket = new Socket("/socket", { params: { token: window.userToken } });

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
socket.connect();

window.channel_user = socket.channel(window.loggedUserChannel, {});
channel_user
  .join()
  .receive("ok", (resp) => {
    console.log(
      "Logged user channel joined successfully " + window.loggedUserChannel,
      resp
    );
  })
  .receive("error", (resp) => {
    console.log("Unable to join", resp);
  });

window.channel_topic_from_url = function () {
  let url = window.location.pathname;
  if (url == "/") {
    return "/items";
  }
  if (contains_string(url, "/items")) {
    if (contains_string(url, "/items/")) {
      return url.match(/.*(\/items\/\w+).*/)[1];
    } else {
      return "/items";
    }
  }
  return url;
};
// Now that you are connected, you can join channels with a topic:
window.channel_topic = decodeURI(channel_topic_from_url());
window.channel = socket.channel(channel_topic, {});
channel
  .join()
  .receive("ok", (resp) => {
    console.log("Joined successfully " + channel_topic, resp);
  })
  .receive("error", (resp) => {
    console.log("Unable to join", resp);
  });

window.channel_push = function (topic, data) {
  channel.push(topic, data);
};
window.channel_push_debounced = debounced(200, channel_push);

window.channel_user_push = function (topic, data) {
  channel_user.push(topic, data);
};
window.channel_user_push_debounced = debounced(200, channel_user_push);

window.flash_info = function (str) {
  document.querySelector(".flash.error").innerHTML = "";
  document.querySelector(".flash.info").innerHTML = str;
};

window.flash_error = function (str) {
  document.querySelector(".flash.info").innerHTML = "";
  document.querySelector(".flash.error").innerHTML = str;
};

channel_user.on("error", (payload) => {
  flash_error(payload.message);
  check_if_logged();
});

channel.on("error", (payload) => {
  flash_error(payload.message);
  check_if_logged();
});

window.check_if_logged = function () {
  if (window.loggedUserId == "") {
    window.location.href = "/auth/google";
  }
};

window.add_cookie_consent_event = function () {
  add_events("[cookie_consent]", "click", function () {
    let xhttp = new XMLHttpRequest();
    xhttp.open("GET", "/accept_cookies", true);
    xhttp.send();

    let element = document.getElementById("cookie_consent");
    element.parentNode.removeChild(element);
  });
};
add_cookie_consent_event();

window.add_marketing_consent_event = function () {
  add_events("[marketing_consent]", "click", function () {
    let xhttp = new XMLHttpRequest();
    if (this.checked) {
      xhttp.open(
        "GET",
        "/put_session?key=marketing_consent&value=agreed",
        true
      );
      xhttp.send();
    } else {
      xhttp.open(
        "GET",
        "/put_session?key=marketing_consent&value=not_agreed",
        true
      );
      xhttp.send();
    }
  });
};
add_marketing_consent_event();

export default socket;
