
var sliderSections = $(".range-slider");
for (let sliderSections of sliderSections) {

  var sliders = sliderSections.getElementsByTagName("input");
  var displayElement = sliderSections.getElementsByClassName("rangeValues")[0];
  displayElement.getElementsByClassName("min")[0].oninput = setVals;
  displayElement.getElementsByClassName("max")[0].oninput = setVals;

  for( var y = 0; y < sliders.length; y++ ){
    if( sliders[y].type ==="range" ){
      sliders[y].removeAttribute("name");
      sliders[y].oninput = getVals;
    }
  }
}

function setVals(){
  var parent = this.parentNode.parentNode;
  var slides = parent.getElementsByTagName("input");
  var field_min = slides[0];
  var field_max = slides[1];

  slides[2].value = field_min.value;
  slides[3].value = field_max.value;
}

function getVals(){
  // Get slider values
  var parent = this.parentNode;
  var slides = parent.getElementsByTagName("input");
  var slide1 = parseFloat( slides[2].value );
  var slide2 = parseFloat( slides[3].value );

  var slides1_name = slides[2].name;
  var slides2_name = slides[3].name;

  // Neither slider will clip the other, so make sure we determine which is larger
  if ( slide1 > slide2 ) {
    var tmp = slide2;
    slide2 = slide1;
    slide1 = tmp;

    if (slides1_name.includes("min")) {
      slides[2].name = slides2_name;
      slides[3].name = slides1_name;
    }
  } else {
    if (slides1_name.includes("max")) {
      slides[2].name = slides2_name;
      slides[3].name = slides1_name;
    }
  }

  var displayElement = parent.getElementsByClassName("rangeValues")[0];
  displayElement.getElementsByClassName("min")[0].value = slide1;
  displayElement.getElementsByClassName("max")[0].value = slide2;

  //need to trigger for only one of the inputs
  $(displayElement.getElementsByClassName("min")[0]).trigger('change');
}
