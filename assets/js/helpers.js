
import * as $ from 'jquery';
import jqueryLazy from 'jquery-lazy';

window.Handlebars = require('handlebars');
Handlebars.registerHelper('json', function(context) {
    return JSON.stringify(context);
});

window.add_events = function(selector, on_event, fun) {
  Array.from(document.querySelectorAll(selector)).forEach(function(element) {
    if (on_event == "click") {
      element.onclick = fun;
    }
    if (on_event == "change") {
      element.onchange = fun;
    }
    if (on_event == "load") {
      element.onload = fun;
    }
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
