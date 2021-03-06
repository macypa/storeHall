// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.scss";

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html";

// Import local files
//
// Local files can be imported directly using relative paths, for example:

import helpers from "./helpers";
import sanitizer from "./sanitizer";
import theme from "./theme";
import socket from "./socket";

import edit_page from "./edit_page";
import pagination from "./functionalities/pagination";
import filter from "./functionalities/filter";
import comments from "./functionalities/comments";
import ratings from "./functionalities/ratings";
import reactions from "./functionalities/reactions";
import mail from "./functionalities/mail";
import payments from "./functionalities/payments";
