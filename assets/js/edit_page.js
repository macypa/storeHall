
add_events("#item_details_price", "change", function () {
  price_event();
});

add_events("#item_details_price_orig", "change", function () {
  price_event();
});

function price_event() {
  let price_orig = $("#item_details_price_orig").val();
  let price = $("#item_details_price").val();

  if (price_orig == "0" || parseFloat(price) >= parseFloat(price_orig)) {
    $("#item_details_discount").prop("disabled", true);
    $("#item_details_discount").val(0);
  } else {
    $("#item_details_discount").prop("disabled", false);
    $("#item_details_discount").val(discount(price, price_orig));
  }
}

add_events("#item_details_discount", "change", function () {
  $("#item_details_price").val(price_from_discount($("#item_details_price_orig").val(), $("#item_details_discount").val()));
});

function discount(price, orig_price) {
  return (((orig_price - price) / orig_price) * 100).toFixed(0)
}

function price_from_discount(orig_price, per) {
  return orig_price - (orig_price * per / 100);
}