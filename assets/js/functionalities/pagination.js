channel_push_filter = function(elem) {
  var next_page = elem.href.slice(elem.href.indexOf('?') + 1);
  var page_for = "";
  if (elem.href.indexOf('&more_') != -1) {
    page_for = elem.href.slice(elem.href.indexOf('&more_') + 6);
  }
  channel.push("filter", { data: next_page, page_for: page_for });
}

$('.page-link').on('click', e => {
  channel_push_filter(e.target);
  e.preventDefault();
});

load_next_items = function() {
  var next_page_link = $('#next-page-link');
  if (next_page_link.is(":visible")) {
    channel_push_filter(next_page_link[0]);
  }
}

reload_next_items = function() {
  if ($("main").height() > $("#items-listing").height()) {
    load_next_items();
  }
  load_lazy_imgs();
}

jQuery(function($) {
  reload_next_items();
  $('main').scroll(function() {
    if($(this).scrollTop() + $(this).innerHeight()+1 >=$(this)[0].scrollHeight) {
      load_next_items();
    } else {
      load_lazy_imgs();
    }
  })
});

window.add_load_more_events = function() {
  add_events("[load-more-topic]", "click", function() {
    var params_attr = this.getAttribute("params")
    var params = params_attr.slice(params_attr.indexOf('?') + 1);
    var show_for = params_attr.slice(params_attr.indexOf('&show_for_') + 10);
    channel.push(this.getAttribute("load-more-topic"), { data: params, show_for: show_for })
  });
}
add_load_more_events();


window.update_next_page_link = function(payload) {

  if (payload.filtered == "[]") {
    $('#next-page-link').hide();
  } else {
    filter_params = payload.filter;
    filter_params = (filter_params.indexOf("page=") == -1) ? location.pathname + "?" + filter_params + "&page=1" : location.pathname + "?" + filter_params;

    $('#next-page-link').attr('href', filter_params.replace(/page=\d+/, function(page_param) {
      return page_param.replace(/\d+/, function(n) {
        return ++n;
      })
    }));

    $('#next-page-link').show();
    reload_next_items();
  }
}
