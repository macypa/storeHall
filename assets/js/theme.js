
import './semantic-ui-css/semantic.js';

$(document).ready(function() {

  $('.ui.checkbox')
    .checkbox()
  ;

  $('#double').range({
    min: 0,
    max: 10,
    start: 5,
    step: 1,
    verbose: true,
    debug: true,
    onChange: function(value) {
      var
        $self = $(this),
        firstVal = $self.range('get thumb value'),
        secVal = $self.range('get thumb value', 'second');
      $('#display-d').html('|' + firstVal + " - " + secVal + '| = ' + value);
    }
  });

});



//import * as $ from 'jquery';
//$("icon").addClass("ui-btn-b ui-shadow ui-corner-all ui-btn-icon-notext ui-btn-inline");
