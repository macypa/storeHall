channel_push_filter = function (elem) {
  var next_page = params_from_href(elem.href);
  var page_for = "";
  if (elem.href.indexOf('&more_') != -1) {
    page_for = elem.href.slice(elem.href.indexOf('&more_') + 6);
  } else if (elem.href.indexOf('?more_') != -1) {
    page_for = elem.href.slice(elem.href.indexOf('?more_') + 6);
  }
  channel.push("filter", { data: next_page, page_for: page_for });
}

params_from_href = function (href) {
  var params = href.slice(href.indexOf('?') + 1);

  try {
    if (contains_string(href, "/users/")) {
      params = params + "&user_id=" + href.match(/\/users\/(.*?)\//)[1];
    }
    if (contains_string(href, "/items/")) {
      params = params + "&id=" + href.match(/\/items\/(\w+)/)[1];
    }
  }
  catch (err) {

  }

  return params;
}

$('.page-link').on('click', e => {
  channel_push_filter(e.target);
  e.preventDefault();
});

load_next_items = function () {
  var next_page_link = $('.next-page-link');
  if (next_page_link.is(":visible")) {
    channel_push_filter(next_page_link[0]);
    rating_badge_color();
  }
}

reload_next_items = function () {
  if ($("main").height() > $("#items-listing").height()) {
    load_next_items();
  }
  rating_badge_color();
  load_lazy_imgs();
}

jQuery(function ($) {
  reload_next_items();
  $('main').scroll(function () {
    if ($(this).scrollTop() + $(this).innerHeight() + 1 >= $(this)[0].scrollHeight) {
      load_next_items();
    }
  })
});

window.add_load_more_events = function () {
  add_events("[load-more-topic]", "click", function () {
    var params_attr = this.getAttribute("params")
    var params = params_from_href(params_attr);
    var show_for = "";
    if (params_attr.indexOf('&show_for_') != -1) {
      show_for = params_attr.slice(params_attr.indexOf('&show_for_') + 10);
    } else if (params_attr.indexOf('?show_for_') != -1) {
      show_for = params_attr.slice(params_attr.indexOf('?show_for_') + 10);
    }
    channel.push(this.getAttribute("load-more-topic"), { data: params, show_for: show_for })
  });
}
add_load_more_events();


window.update_next_page_link = function (payload) {

  if (payload.filtered == "[]") {
    $('.next-page-link').hide();
  } else {
    filter_params = payload.filter;
    filter_params = (filter_params.indexOf("page=") == -1) ? location.pathname + "?" + filter_params + "&page=1" : location.pathname + "?" + filter_params;

    $('.next-page-link').attr('href', filter_params.replace(/page=\d+/, function (page_param) {
      return page_param.replace(/\d+/, function (n) {
        return ++n;
      })
    }));

    $('.next-page-link').show();
    reload_next_items();
  }
}
