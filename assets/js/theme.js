
function requireAll(r) { r.keys().forEach(r); }
requireAll(require.context('./components/', true, /\.js$/));

window.update_notifications_counter_alert = function() {
  var counter = document.querySelector("#alert_new_notification")
  counter.classList.add('counter')
  counter.innerHTML = $("#new_notifications").children().length;
}

window.load_lazy_imgs = function() {
  $('.lazy').filter(function(){
                   return !$(this).attr('data-src').startsWith("{{");
                }).Lazy({
    // visibleOnly: true,
	  onError: function(element) {
		  console.warn("img can't be loaded " + element[0].getAttribute("data-src"));
	  },
  });
};

window.show_hide = function(element_id) {
    var x = document.getElementById(element_id);
    if (x.style.display === "none") {
        x.style.display = "block";
    } else {
        x.style.display = "none";
    }
}

$( document ).ready(function() {
  var form = $('#form-filter');
  var urlParams = new URLSearchParams(window.location.search);
  for(key of urlParams.keys()) {
    var input = form.find('[name="' + key + '"]');
      if (input.closest(".tab")[0] && input.closest(".tab")[0].getElementsByClassName("collapsible")[0]) {
        input.closest(".tab")[0].getElementsByClassName("collapsible")[0].checked = true;
      }
  }
});

window.local_time_zone = function() {
  return Intl.DateTimeFormat().resolvedOptions().timeZone;
}


import formatDistance from 'date-fns/formatDistance';
import format from 'date-fns/format';
import bg from 'date-fns/locale/bg'

window.timeago = function() {
  var time = $(".timeago").each(function() {
    var datetime = $( this ).first().text( ).trim();

    try {
      $( this ).attr("title",
              format(new Date(datetime), 'MM/dd/yyyy HH:mm:ss', {
                locale: bg
              })
            );
    } catch(error) {}

    try {
      $( this ).first().text(
              formatDistance(new Date(datetime), new Date(), {
                locale: bg
              })
            );
    } catch(error) {}
  });

};
$( document ).ready(function() {
  timeago();
  load_lazy_imgs();
});
