
$('.page-link').on('click', e => {
  var next_page = e.target.href.slice(e.target.href.indexOf('?') + 1);
  var page_more = e.target.href.slice(e.target.href.indexOf('&more_') + 6);
  channel.push("filter", { data: next_page, page_more: page_more })
  e.preventDefault();
});

jQuery(function($) {
  $('main').scroll(function() {
    if($(this).scrollTop() + $(this).innerHeight()+1 >=$(this)[0].scrollHeight) {
      var next_page_link = $('#next-page-link')[0];
      if (!next_page_link.getAttribute("disabled")) {
        var next_page = next_page_link.href.slice(next_page_link.href.indexOf('?') + 1);
        var page_more = next_page_link.href.slice(next_page_link.href.indexOf('&more_') + 6);
        channel.push("filter", { data: next_page, page_more: page_more });

        $('#next-page-link')[0].setAttribute("disabled", "disabled");
      }
    }
  })
});

function add_load_more_events() {
  add_events("[load-more-topic]", "click", function() {
    var params_attr = this.getAttribute("params")
    var params = params_attr.slice(params_attr.indexOf('?') + 1);
    var show_more = params_attr.slice(params_attr.indexOf('&show_for_') + 10);
    channel.push(this.getAttribute("load-more-topic"), { data: params, show_more: show_more })
  });
}
add_load_more_events();


window.update_next_page_link = function(filter_params) {
  filter_params = (filter_params.indexOf("page=") == -1) ? location.pathname + "?" + filter_params + "&page=1" : location.pathname + "?" + filter_params;

  $('#next-page-link').attr('href', filter_params.replace(/page=\d+/, function(page_param) {
    return page_param.replace(/\d+/, function(n) {
      return ++n;
    })
  }));
}

channel.on("show_more_comments", payload => {

  var comments_template_source = "{{#each this}}<comment>" +
       unescape(document.getElementById("comment_template").innerHTML)
       .replace(/\{"\w+_template_tag_id":"\w+_template"\}/g, "{{json details}}") +
       "</comment>{{/each}}";
  var comments_template = Handlebars.compile(comments_template_source);

  var filtered_comments = comments_template( JSON.parse(payload.filtered) )
  if (payload.filter.indexOf("show_for_comment_id=") == -1) {
    document.querySelector("comments").insertAdjacentHTML( 'beforeend', filtered_comments);
  } else {
    var comment_id = payload.filter.match("show_for_comment_id=\\d+");
    var link_node = document.getElementById(comment_id)
    link_node.parentNode.getElementsByTagName("comment-replies")[0].insertAdjacentHTML( 'beforeend', filtered_comments);
    link_node.innerHTML = "";
  }
  $(".timeago").timeago();
  add_load_more_events();
})
