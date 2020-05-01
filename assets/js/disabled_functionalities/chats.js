function add_chat_events() {
  add_events("[msg-topic]", "click", function () {
    let body_field_value = this.parentNode.getElementsByClassName("body")[0]
      .value;
    let msg_field_value = JSON.parse(
      this.parentNode.getElementsByClassName("msg")[0].value
    );
    msg_field_value.details = {};
    msg_field_value.details.body = body_field_value;

    if (channel_user.state == "joined") {
      channel_user_push_debounced(this.getAttribute("msg-topic"), {
        data: msg_field_value,
      });
    } else {
      channel_push_debounced(this.getAttribute("msg-topic"), {
        data: msg_field_value,
      });
    }
  });
}
add_chat_events();

function add_chat_container_events() {
  add_events("[load-chat-msgs]", "click", function () {
    this.removeAttribute("load-chat-msgs");
    this.onclick = null;
    let msg_field_value = JSON.parse(
      document.getElementById(this.innerText).getElementsByClassName("msg")[0]
        .value
    );
    if (channel_user.state == "joined") {
      channel_user_push_debounced("msg:load_chat_room", {
        data: msg_field_value,
      });
    } else {
      channel_push_debounced("msg:load_chat_room", { data: msg_field_value });
    }
  });
}
add_chat_container_events();

function add_chat_room_events() {
  add_events("[delete_chat_room]", "click", function () {
    let msg_field_value = JSON.parse(
      document
        .getElementById(this.getAttribute("delete_chat_room"))
        .getElementsByClassName("msg")[0].value
    );
    if (channel_user.state == "joined") {
      channel_user_push_debounced("msg:delete_chat_room", {
        data: msg_field_value,
      });
    } else {
      channel_push_debounced("msg:delete_chat_room", { data: msg_field_value });
    }
  });
}
add_chat_room_events();

import chat_msg_template from "../hbs/chat.hbs";

function on_new_msg_event(payload) {
  let new_msg = JSON.parse(payload.new_msg);
  add_new_msg_to_chat_room(new_msg);

  if (window.loggedUserId == new_msg.author_id) {
    new_msg.me_you = "me";
  } else {
    new_msg.me_you = "you";
  }

  let new_msg_html = chat_msg_template(new_msg);
  document.querySelector("chats").insertAdjacentHTML("beforeend", new_msg_html);

  update_notifications_counter_alert();
}

function add_new_msg_to_chat_room(new_msg) {
  if (window.loggedUserId == new_msg.author_id) {
    new_msg.me_you = "me";
  } else {
    new_msg.me_you = "you";
  }

  let new_msg_html = chat_msg_template(new_msg);

  let topic_id = "";
  if (window.loggedUserId == new_msg.user_id) {
    topic_id = topic_id + new_msg.owner_id;
  } else {
    topic_id = topic_id + new_msg.user_id;
  }

  if (new_msg.item_id) {
    topic_id = topic_id + "_" + new_msg.item_id;
  }
  let topic = document.getElementById(topic_id);
  if (topic) {
    topic
      .getElementsByTagName("ul")[0]
      .insertAdjacentHTML("beforeend", new_msg_html);
  }

  // add_chat_events()
}

function on_chats_for_room_event(payload) {
  JSON.parse(payload.chats_for_room).forEach(add_new_msg_to_chat_room);
}

channel_user.on("new_msg", (payload) => {
  on_new_msg_event(payload);
});
channel_user.on("chats_for_room", (payload) => {
  on_chats_for_room_event(payload);
});

channel.on("new_msg", (payload) => {
  on_new_msg_event(payload);
});
channel.on("chats_for_room", (payload) => {
  on_chats_for_room_event(payload);
});
