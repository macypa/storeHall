
window.add_reaction_events = function() {
  add_events("[reaction-topic]", "click", function() {
    if (this.getAttribute("reaction-topic").startsWith("reaction")) {
      channel.push(this.getAttribute("reaction-topic"), { data: this.getAttribute("data") })
    } else {
      channel_user.push(this.getAttribute("reaction-topic"), { data: this.getAttribute("data") })
    }
  });
};
add_reaction_events();

window.reaction_persisted_event = function(payload) {
  $("." + payload.reaction + "z_icon[data='" + payload.data + "']").addClass(payload.reaction);
};

channel.on("reaction_persisted", payload => {
  reaction_persisted_event(payload);
});

channel_user.on("reaction_persisted", payload => {
  reaction_persisted_event(payload);
});
