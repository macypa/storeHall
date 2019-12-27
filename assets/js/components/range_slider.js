
var sliderSections = $(".range-slider");
for (let sliderSections of sliderSections) {

  var sliders = sliderSections.getElementsByTagName("input");
  var displayElement = sliderSections.getElementsByClassName("rangeValues")[0];

    const myHandler = (event) => setVals(event);
    const dHandler = debounced(200, myHandler);
  displayElement.getElementsByClassName("min")[0].oninput = dHandler;
  displayElement.getElementsByClassName("max")[0].oninput = dHandler;

  for( var y = 0; y < sliders.length; y++ ){
    if( sliders[y].type ==="range" ){
      sliders[y].removeAttribute("name");
      sliders[y].oninput = getVals;
    }
  }
}

function setVals(e) {
  var parent = e.target.parentNode.parentNode;
  var slides = parent.getElementsByTagName("input");
  var field_min = slides[0];
  var field_max = slides[1];

  slides[2].value = field_min.value;
  if (field_max.value > 0) {
    slides[3].value = field_max.value;
  }

  trigger_event(parent);
}

function trigger_event(parent){
  //need to trigger for only one of the inputs
  $(parent.getElementsByClassName("min-slider")[0]).trigger('change')
}

function getVals(){
  // Get slider values
  var parent = this.parentNode;
  var slides = parent.getElementsByTagName("input");
  var slides_min = slides[0].getAttribute("min") || 0;
  var slides_max = slides[0].getAttribute("max") || 100;
  var slide1 = parseFloat( slides[0].value );
  var slide2 = parseFloat( slides[1].value );

  var slides1_name = slides[0].name;
  var slides2_name = slides[1].name;

  // Neither slider will clip the other, so make sure we determine which is larger
  if ( slide1 > slide2 ) {
    var tmp = slide2;
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

  var displayElement = parent.parentNode.getElementsByClassName("rangeValues")[0];
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
