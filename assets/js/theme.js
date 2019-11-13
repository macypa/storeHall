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
