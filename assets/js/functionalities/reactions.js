
add_events("[reaction-topic]", "click", function() {
  if (this.getAttribute("reaction-topic").startsWith("reaction")) {
    channel.push(this.getAttribute("reaction-topic"), { data: this.getAttribute("data") })
  } else {
    channel_user.push(this.getAttribute("reaction-topic"), { data: this.getAttribute("data") })
  }
});
