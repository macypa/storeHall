// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
//import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative paths, for example:

import * as $ from 'jquery';
import jqueryLazy from 'jquery-lazy';

import timeago from 'timeago'
import timeago_bg from 'timeago/locales/jquery.timeago.bg.js'
// Display original dates older than 24 hours
//$.timeago.settings.cutoff = 1000*60*60*24;

import theme from "./theme"
import socket from "./socket"
