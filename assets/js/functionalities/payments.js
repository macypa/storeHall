function on_payment_events() {
  timeago();
  load_lazy_imgs();
  add_load_more_events();
}

let payments_template_source =
  "{{#each this}}" +
  unescape(document.getElementById("payment_template").innerHTML) +
  "{{/each}}";
let payments_template = Handlebars.compile(payments_template_source);
//import payments_template from "../hbs/payments.hbs"
channel.on("filtered_payments", (payload) => {
  let filtered_payments = payments_template(JSON.parse(payload.filtered));
  if (payload.filter.indexOf("page=") == -1) {
    document.querySelector("payments").innerHTML = filtered_payments;
  } else {
    document
      .querySelector("payments")
      .insertAdjacentHTML("beforeend", filtered_payments);
  }

  on_payment_events();
  update_next_page_link(payload);
});

window.add_payment_amount_events = function () {
  add_events("#payment_details_credits", "change", function () {
    document.querySelector("#payment_details_amount").value = (
      this.value * 0.01
    ).toFixed(2);
  });
};
add_payment_amount_events();
