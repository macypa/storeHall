function requireAll(r) { r.keys().forEach(r); }
requireAll(require.context('./components/', true, /\.js$/));


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
      if (input.closest(".tab")[0].getElementsByClassName("collapsible")[0]) {
        input.closest(".tab")[0].getElementsByClassName("collapsible")[0].checked = true;
      }
  }
});
