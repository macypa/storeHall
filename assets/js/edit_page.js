
add_events("#item_details_price", "change", function () {
  $("#item_details_discount").val(discount($("#item_details_price").val(), $("#item_details_price_orig").val()));
});

add_events("#item_details_price_orig", "change", function () {
  $("#item_details_discount").val(discount($("#item_details_price").val(), $("#item_details_price_orig").val()));
});

add_events("#item_details_discount", "change", function () {
  $("#item_details_price").val(price_from_discount($("#item_details_price_orig").val(), $("#item_details_discount").val()));
});

function discount(price, orig_price) {
  return (((orig_price - price) / orig_price) * 100).toFixed(0)
}

function price_from_discount(orig_price, per) {
  return orig_price - (orig_price * per / 100);
}