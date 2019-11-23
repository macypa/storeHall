
add_events("[reaction-topic]", "click", function() {
  channel.push(this.getAttribute("reaction-topic"), { data: this.getAttribute("data") })
});
