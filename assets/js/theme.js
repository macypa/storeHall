
function requireAll(r) { r.keys().forEach(r); }
requireAll(require.context('./components/', true, /\.js$/));

window.update_notifications_counter_alert = function () {
  let counter = document.querySelector("#alert_new_notification")
  counter.classList.add('counter')
  counter.innerHTML = $("#new_notifications").children().length;
}

window.load_lazy_imgs = function () {
  $('.lazy[data-src]').filter(function () {
    return !$(this).attr('data-src').startsWith("{{");
  }).Lazy({
    // visibleOnly: true,
    onError: function (element) {
      console.warn("img can't be loaded " + element[0].getAttribute("data-src"));
    },
  });
};

$(document).ready(function () {
  let form = $('#form-filter');
  let urlParams = new URLSearchParams(window.location.search);
  for (const [key, value] of urlParams) {
    let input = form.find('[name="' + key + '"]');
    if (input.closest(".tab")[0] && input.closest(".tab")[0].getElementsByClassName("collapsible")[0]) {
      input.closest(".tab")[0].getElementsByClassName("collapsible")[0].checked = true;
    }
  }
});

import formatDistance from 'date-fns/formatDistance';
import format from 'date-fns/format';
import bg from 'date-fns/locale/bg'

window.timeago = function () {
  let time = $(".timeago").each(function () {
    let datetime = $(this).first().text().trim();

    try {
      $(this).attr("title",
        format(new Date(datetime), 'MM/dd/yyyy HH:mm:ss', {
          locale: bg
        })
      );
    } catch (error) { }

    try {
      $(this).first().text(
        formatDistance(new Date(datetime), new Date(), {
          locale: bg,
          addSuffix: true
        })
      );
    } catch (error) { }
  });

};

$("textarea").focusout(function () {
  this.style.height = "3em";
});

$('textarea').on('focus', function () {
  this.style.height = "";
  this.style.height = this.scrollHeight + "px"
});

$('textarea').on('input', function () {
  this.style.height = "";
  this.style.height = this.scrollHeight + "px"
});

window.format_money = function () {
  $(".money_value").each(function () {
    let money_value = this.innerHTML;
    const parsed = parseFloat(money_value);
    if (isNaN(parsed)) {
      this.innerHTML = "0";
    } else {
      this.innerHTML = parsed.toFixed(2);
    }
  });
};

$(document).ready(function () {
  timeago();
  format_money();
  load_lazy_imgs();
});
