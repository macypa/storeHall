function requireAll(r) { r.keys().forEach(r); }
requireAll(require.context('./components/', true, /\.js$/));

//import * as $ from 'jquery';
//$("icon").addClass("ui-btn-b ui-shadow ui-corner-all ui-btn-icon-notext ui-btn-inline");
