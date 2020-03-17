
window.add_reaction_events = function () {
  add_events("[reaction-topic]", "click", function () {
    channel_user.push(this.getAttribute("reaction-topic"), { data: this.getAttribute("data") })
  });
};
add_reaction_events();

$('.alerts_panel').click(function () {
  var pos = $(this).position();
  var dropdown = $(this).find('.dropdown');
  dropdown.css("top", $(this).position().top + $(this).height());
  dropdown.toggle();
}).mouseleave(function () {
  $(this).find('.dropdown').hide();
});

window.reaction_persisted_event = function (payload) {
  var reaction_class = payload.reaction;
  if (reaction_class.startsWith("alert")) {
    reaction_class = "alert";
  }

  $("[data='" + payload.data + "']").each(function () {
    var klass = $(this).attr("class");
    if (klass.includes(reaction_class + "z_icon")) {
      return;
    }

    var myRegexp = /svg_icon (.*?)z_icon/g;
    var match = myRegexp.exec(klass);
    if (!!match) {
      $(this).removeClass(match[1]);
    }

    removeClassStartingWith($(this), "alert_");
  })

  $("." + reaction_class + "z_type[data='" + payload.data + "']").toggleClass(payload.reaction);
  $("." + reaction_class + "z_icon[data='" + payload.data + "']").toggleClass(payload.reaction);
};

function removeClassStartingWith(node, begin) {
  node.removeClass(function (index, className) {
    return (className.match(new RegExp("\\b" + begin + "\\S+", "g")) || []).join(' ');
  });
}

channel.on("reaction_persisted", payload => {
  reaction_persisted_event(payload);
});

channel_user.on("reaction_persisted", payload => {
  reaction_persisted_event(payload);
});
