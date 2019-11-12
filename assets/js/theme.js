$(document).ready(function() {

});

function getVals(){
  // Get slider values
  var parent = this.parentNode;
  var slides = parent.getElementsByTagName("input");
    var slide1 = parseFloat( slides[0].value );
    var slide2 = parseFloat( slides[1].value );
  // Neither slider will clip the other, so make sure we determine which is larger
  if( slide1 > slide2 ){ var tmp = slide2; slide2 = slide1; slide1 = tmp; }

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
//import * as $ from 'jquery';
//$("icon").addClass("ui-btn-b ui-shadow ui-corner-all ui-btn-icon-notext ui-btn-inline");
