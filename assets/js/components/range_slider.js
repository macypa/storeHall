
function getVals(){
  // Get slider values
  var parent = this.parentNode;
  var slides = parent.getElementsByTagName("input");
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

  var displayElement = parent.getElementsByClassName("rangeValues")[0];
  displayElement.getElementsByClassName("min")[0].innerHTML = slide1;
  displayElement.getElementsByClassName("max")[0].innerHTML = slide2;
}

window.onload = function(){
  // Initialize Sliders
  var sliderSections = document.getElementsByClassName("range-slider");
  for( var x = 0; x < sliderSections.length; x++ ){
    var sliders = sliderSections[x].getElementsByTagName("input");
    for( var y = 0; y < sliders.length; y++ ){
      if( sliders[y].type ==="range" ){
        sliders[y].oninput = getVals;
        // Manually trigger event first time to display values
        sliders[y].oninput();
      }
    }
  }
}
