
import * as $ from 'jquery';
import jqueryLazy from 'jquery-lazy';

window.sanitize = function (str) {
  var temp = document.createElement('div');
  temp.textContent = str;
  return temp.innerHTML;
}

window.regExp_escape = function (s) {
  return s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
};

window.isNumeric = function (num) {
  return num != null && !isNaN(num) && (num + "").trim() != ""
}

window.isString = function (obj) {
  if (obj == null) return true;
  return typeof obj === "string";
}

window.isEmpty = function (obj) {
  if (obj == null) return true;
  if (typeof obj === "string" && (obj == "" || obj.trim() == "")) return true;

  for (var prop in obj) {
    if (obj.hasOwnProperty(prop)) {
      return false;
    }
  }

  return JSON.stringify(obj) === JSON.stringify({}) || JSON.stringify(obj) === JSON.stringify([]);
}

window.Handlebars = require('handlebars');
Handlebars.registerHelper('json', function (context) {
  return JSON.stringify(context);
});

window.add_events = function (selector, on_event, fun) {
  Array.from(document.querySelectorAll(selector)).forEach(function (element) {
    if (on_event == "click") {
      element.onclick = fun;
    }
    if (on_event == "change") {
      if (element.getAttribute("type") == "text") {
        element.oninput = fun;
        element.onchange = fun;
      } else {
        element.onchange = fun;
      }
    }
    if (on_event == "load") {
      element.onload = fun;
    }
  });
};

window.show_hide = function (element_id) {
  var x = document.getElementById(element_id);
  if (x.style.display === "none") {
    x.style.display = "block";
  } else {
    x.style.display = "none";
  }
}

window.throttled = function (delay, fn) {
  let lastCall = 0;
  return function (...args) {
    const now = (new Date).getTime();
    if (now - lastCall < delay) {
      return;
    }
    lastCall = now;
    return fn(...args);
  }
}

window.debounced = function (delay, fn) {
  let timerId;
  return function (...args) {
    if (timerId) {
      clearTimeout(timerId);
    }
    timerId = setTimeout(() => {
      fn(...args);
      timerId = null;
    }, delay);
  }
}

window.get_city = function () {
  $.ajax({
    url: "https://geolocation-db.com/jsonp",
    jsonpCallback: "callback",
    dataType: "jsonp",
    success: function (location) {
      window.city = location.city;
      // $('#country').html(location.country_name);
      // $('#state').html(location.state);
      // $('#city').html(location.city);
      // $('#latitude').html(location.latitude);
      // $('#longitude').html(location.longitude);
      // $('#ip').html(location.IPv4);
    }
  });
}

$("input").not($(":button")).keypress(function (evt) {
  if (evt.keyCode == 13) {
    let iname = $(this).val();
    if (iname !== 'Submit') {
      var fields = $(this).parents('form:eq(0),body').find('button, input, textarea, select');
      var index = fields.index(this);
      if (index > -1 && (index + 1) < fields.length) {
        fields.eq(index + 1).focus();
      }
      return false;
    }
  }
});
