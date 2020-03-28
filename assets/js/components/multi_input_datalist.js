
$(document).ready(function () {
  init();
});

function init() {
  let containers = $(".datalist_container");

  for (let container of containers) {
    let input_field = container.getElementsByTagName("input")[0];
    input_field.setAttribute("hidden", '');

    if (is_editable(container)) {
      let cloned_input_field = input_field.cloneNode(true);
      cloned_input_field.value = '';
      cloned_input_field.setAttribute("value", '');
      cloned_input_field.removeAttribute("id");
      cloned_input_field.removeAttribute("name");
      cloned_input_field.removeAttribute("hidden");
      cloned_input_field.setAttribute("placeholder", container.getAttribute("placeholder"));
      if (!cloned_input_field.classList.contains("datalist_editable_input")) {
        cloned_input_field.classList.add("datalist_input");
        input_field.insertAdjacentHTML('afterend', cloned_input_field.outerHTML);
      } else {
        input_field.insertAdjacentHTML('beforebegin', cloned_input_field.outerHTML);
      }

      input_field = get_input(container);
      input_field.onchange = add_item;
      disable_enter_key_press(input_field, add_item);

      let select = container.getElementsByTagName("select");
      if (select[0]) {
        select[0].classList.add("datalist_select");
        select[0].selectedIndex = -1;

        if (cloned_input_field.classList.contains("datalist_editable_input")) {
          select[0].onchange = select_add_item;
          select[0].insertAdjacentHTML('afterbegin', "<option value='" + container.getAttribute("placeholder") + "'>" + container.getAttribute("placeholder") + "</option>");
          select[0].value = "";
          $(input_field).hide();
          input_field.onfocusout = hide_input;
        } else {
          select[0].onchange = add_item;
        }

      }

      let datalist = container.getElementsByTagName("datalist");
      if (datalist[0] && !input_field.getAttribute("list")) {
        datalist[0].classList.add("datalist_options")
        input_field.setAttribute("list", datalist[0].id);
      }
    }
    input_field.insertAdjacentHTML('afterEnd', "<div class='datalist_items'></div>");


    update_placeholder(container);
  }
}

function select_add_item(e) {
  e.stopPropagation();
  e.preventDefault();

  let select = e.target;
  let container = get_parent_container(select);
  let input_field = get_input(container);

  if (select.value == container.getAttribute("placeholder")) {
    $(input_field).show();
    input_field.focus();
    select.value = "";
  } else {
    add_item(e);
    $(input_field).hide();
  }
}
function hide_input(e) {
  e.stopPropagation();
  e.preventDefault();

  $(e.target).hide();
}

function disable_enter_key_press(node, fun) {
  node.onkeypress = function (e) {
    let key = e.charCode || e.keyCode || 0;
    if (key == 13) {
      e.stopPropagation();
      e.preventDefault();
      fun(e);
    }
  };
}

function get_parent_container(child) {
  return child.closest(".datalist_container");
}

function get_input(container) {
  let input = container.querySelector(".datalist_input");
  if (!input) {
    input = container.querySelector("input");
  }
  return input;
}

function get_form_input(container) {
  return container.querySelector("input[name]");
}

function get_items(container) {
  return container.querySelector(".datalist_items");
}

function get_item_html(item) {
  return item.querySelector(".datalist_item_html");
}

function has_select_tag(container) {
  return container.querySelector("select");
}
function is_select_editable(container) {
  if (container.querySelector(".datalist_editable_input")) {
    return true;
  }
  return false;
}


function is_editable(container) {
  if (container.querySelector("input[name]")) {
    return true;
  }
  return false;
}

function key_value_separator(container) {
  return container.getAttribute("key_value_separator");
}

function get_input_data(container) {
  let data = {};
  let input = container.querySelector("input[name]");
  data.key_value_separator = key_value_separator(container);

  if (!input) {
    data.str = get_input(container).value;
  } else {
    data.str = input.getAttribute("value");

    if (!data.str) {
      data.str = input.value;
    }
  }

  try {
    data.obj = JSON.parse(data.str);
    data.is_array = true;
  } catch (error) {
    data.is_string = true;
    data.obj = data.str.split(",");
    if (data.obj[0] == '') {
      data.obj = [];
    }
  }

  if (data.obj == null) {
    data.is_string = true;
    data.obj = [];
  } else if (Array.isArray(data.obj)) {
    data.obj = data.obj.map(value => item_data(data, value));
  } else {
    data.obj = [];
  }

  return data;
}

function remove_item(e) {
  e.stopPropagation();

  let container = get_parent_container(this);
  this.parentElement.parentElement.removeChild(this.parentElement);

  update_input_field(container);
};

function add_item(e) {
  e.stopPropagation();
  e.preventDefault();

  let select = e.target;
  let container = get_parent_container(select);
  let input_field_data = get_input_data(container);

  let key = select.value;
  if (isEmpty(key)) return;

  let human_readable_key = select.value;
  let custom_value = "";
  if (has_select_tag(container)) {
    let option = select.querySelector("option[value='" + select.value + "']");
    if (option) {
      custom_value = option.getAttribute("data-template-value");
      human_readable_key = option.innerText;
    }

    if (is_select_editable(container)) {
      $(get_input(container)).hide();
    }
  }

  if (custom_value == null) {
    custom_value = "";
  }

  if (input_field_data.key_value_separator != null) {
    let first_key_part = (human_readable_key + "").split(input_field_data.key_value_separator)[0];
    custom_value = human_readable_key.slice(human_readable_key.indexOf(first_key_part) + first_key_part.length + 1);
    human_readable_key = first_key_part;
    key = (key + "").split(input_field_data.key_value_separator)[0];;
  }

  let item = placeholder_item_html(container, input_field_data, key, human_readable_key, custom_value);
  get_items(container).insertAdjacentHTML('beforeend', item);

  e.target.value = '';
  update_input_field(container);
  update_items_events(container);
};

function placeholder_item_html(container, data, key, human_readable_key, value) {
  return "<div class='datalist_item'" +
    (is_editable(container) ?
      " draggable='true'>\
        <div class='datalist_del'>\
          <div class='datalist_x'></div>\
          <div class='datalist_x'></div>\
        </div>"
      : ">")
    + "<div class='datalist_item_html' key='" + sanitize(key) + "' value='" + sanitize(value) + "'>" + html_from_template(container, data, key, human_readable_key, value) + "</div>\
      </div> ";
}

function update_placeholder(container) {

  let input_field_data = get_input_data(container);

  let items = get_items(container);
  // transform data to json to work with it
  input_field_data.obj.forEach(i_data => {
    let human_readable_key = i_data.key;
    if (has_select_tag(container)) {
      let option = container.querySelector("select").querySelector("option[value='" + i_data.key + "']");
      if (option) {
        human_readable_key = option.innerText;
      }
    }
    let item = placeholder_item_html(container, input_field_data, i_data.key, human_readable_key, i_data.value);
    items.insertAdjacentHTML('beforeend', item);
  })

  update_items_events(container);
}

function update_items_events(container) {
  if (!is_editable(container)) return;

  let item_oninputs = container.getElementsByClassName("datalist_item_oninput_event");
  Array.from(item_oninputs).forEach(element => {
    element.oninput = update_on_input_event;
    disable_enter_key_press(element, function () { });
  });

  let del_buttons = container.getElementsByClassName("datalist_del");
  Array.from(del_buttons).forEach(element => {
    element.onclick = remove_item;
  });

  add_drag_events(get_items(container), update_after_drag_drop);
}

function update_on_input_event(e) {

  let item_html = e.target.closest(".datalist_item_html");
  data_value = item_html.setAttribute("value", this.value);

  this.setAttribute("value", this.value);
  update_input_field(get_parent_container(this))
}

function update_after_drag_drop(items) {
  update_items_events(get_parent_container(items));
  update_input_field(get_parent_container(items));
}

function get_html_template(container, data) {
  let template_data_key = "_key_";
  let template_data_hkey = "_hkey_";
  let template_data_value = "_value_";
  let template = "<span>" + template_data_hkey + "</span>";
  if (data.key_value_separator != null) {
    template = "<span>" + template_data_hkey + ":</span><span>" + template_data_value + "</span>";
  }

  let datalist_item_template = container.getElementsByTagName("template");
  if (datalist_item_template[0]) {
    template = datalist_item_template[0].innerHTML;

    template_data_key = datalist_item_template[0].getAttribute("data-key") || template_data_key;
    template_data_hkey = datalist_item_template[0].getAttribute("data-hkey") || template_data_hkey;
    template_data_value = datalist_item_template[0].getAttribute("data-value") || template_data_value;
  }

  let json_data = {};
  json_data.html = template;
  json_data.key = template_data_key;
  json_data.hkey = template_data_hkey;
  json_data.value = template_data_value;
  return json_data;
}

function html_from_template(container, data, key, human_readable_key, value) {
  let template = get_html_template(container, data)

  html = template.html.split(template.value).join(sanitize(value))
  html = html.split(template.key).join(sanitize(key));
  html = html.split(template.hkey).join(sanitize(human_readable_key));

  return html;
}

function parse_item_data(container, data, item) {
  let item_html = get_item_html(item);
  data_key = item_html.getAttribute("key");
  data_value = item_html.getAttribute("value");

  if (isNumeric(data_value)) data_value = parseInt(data_value);

  if (data.is_string) return data_key;

  if (data.key_value_separator == null) return data_key;

  return data_key + data.key_value_separator + data_value;
}

function item_data(data, value) {
  if (isNumeric(value)) value = parseInt(value);

  let key = value + "";
  if (data.key_value_separator != null) {
    key = key.split(data.key_value_separator)[0];
    value = key.slice(key.indexOf(key) + key.length + 1);
  }

  let json_data = {};
  json_data.key = key;
  json_data.value = value;
  return json_data;
}

function update_input_field(container) {
  let form_input_field = get_form_input(container);
  if (!form_input_field) return;

  let items = get_items(container);
  let data = get_input_data(container);

  let input_data = new Array();

  const children = [...items.getElementsByClassName('datalist_item')];
  children.forEach(function (item) {
    let item_data = parse_item_data(container, data, item);
    input_data.push(item_data);
  });

  if (data.is_string) {
    form_input_field.value = input_data.join(",");
  } else {
    form_input_field.value = JSON.stringify(input_data);
  }

  form_input_field.setAttribute("value", form_input_field.value);
  $(form_input_field).trigger('change');
}
