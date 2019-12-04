
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

  $("[data='" + payload.data + "']").each(function() {
    var klass = $(this).attr("class");
    if (klass.includes(payload.reaction)) {
      return;
    }

    var myRegexp = /svg_icon (.*?)z_icon/g;
    var match = myRegexp.exec(klass);
    $(this).removeClass(match[1]);
  })

  $("." + payload.reaction + "z_icon[data='" + payload.data + "']").toggleClass(payload.reaction);
};

channel.on("reaction_persisted", payload => {
  reaction_persisted_event(payload);
});

channel_user.on("reaction_persisted", payload => {
  reaction_persisted_event(payload);
});
