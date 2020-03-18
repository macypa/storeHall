
let sliderSections = $(".range-slider");
for (let sliderSections of sliderSections) {

  let sliders = sliderSections.getElementsByTagName("input");
  let displayElement = sliderSections.getElementsByClassName("rangeValues")[0];

  const myHandler = (event) => setVals(event);
  const dHandler = debounced(200, myHandler);
  displayElement.getElementsByClassName("min")[0].oninput = dHandler;
  displayElement.getElementsByClassName("max")[0].oninput = dHandler;

  for (let y = 0; y < sliders.length; y++) {
    if (sliders[y].type === "range") {
      sliders[y].removeAttribute("name");
      sliders[y].oninput = getVals;
    }
  }
}

function setVals(e) {
  let parent = e.target.parentNode.parentNode;
  let slides = parent.getElementsByTagName("input");
  let field_min = slides[0];
  let field_max = slides[1];

  slides[2].value = field_min.value;
  if (field_max.value > 0) {
    slides[3].value = field_max.value;
  }

  trigger_event(parent);
}

function trigger_event(parent) {
  //need to trigger for only one of the inputs
  $(parent.getElementsByClassName("min-slider")[0]).trigger('change')
}

function getVals() {
  // Get slider values
  let parent = this.parentNode;
  let slides = parent.getElementsByTagName("input");
  let slides_min = slides[0].getAttribute("min") || 0;
  let slides_max = slides[0].getAttribute("max") || 100;
  let slide1 = parseFloat(slides[0].value);
  let slide2 = parseFloat(slides[1].value);

  let slides1_name = slides[0].name;
  let slides2_name = slides[1].name;

  // Neither slider will clip the other, so make sure we determine which is larger
  if (slide1 > slide2) {
    let tmp = slide2;
    slide2 = slide1;
    slide1 = tmp;

    if (slides1_name.includes("min")) {
      slides[0].name = slides2_name;
      slides[1].name = slides1_name;
    }
  } else {
    if (slides1_name.includes("max")) {
      slides[0].name = slides2_name;
      slides[1].name = slides1_name;
    }
  }

  let displayElement = parent.parentNode.getElementsByClassName("rangeValues")[0];
  if (displayElement.getElementsByClassName("min")[0].value != slide1) {
    displayElement.getElementsByClassName("min")[0].value = slide1;
  }
  if (displayElement.getElementsByClassName("max")[0].value != slide2) {
    displayElement.getElementsByClassName("max")[0].value = slide2;
  }

  if (slide1 == slides_min || slide2 == slides_min) {
    displayElement.getElementsByClassName("min")[0].value = '';
  }
  if (slide1 == slides_max || slide2 == slides_max) {
    displayElement.getElementsByClassName("max")[0].value = '';
  }
}
