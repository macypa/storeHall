
function update_input_field(select, trigger) {
  let placeholder = select.parentElement.querySelector(".select7_items");
  let input_field = select.parentElement.parentElement.querySelector(".select7_input");
  input_field.value = "";
  let json = input_field.getAttribute("format") == "json";

  const children = [...placeholder.getElementsByClassName('select7_item')];
  if (json) {
    input_field.value = "{";
  }
  children.forEach(function (item) {
    let option = item.getElementsByClassName('select7_content')[0];
    let option_value = option.getAttribute("data-option-value");

    if (json) {
      let spinner = item.getElementsByClassName('select7_spinner')[0];
      let spinner_value = spinner.getAttribute("value");

      if (input_field.value == "{") {
        input_field.value += '"';
      } else {
        input_field.value += ', "';
      }
      input_field.value += option_value + '": ' + spinner_value;
    } else {
      if (input_field.value != "") {
        input_field.value += ";";
      }
      input_field.value += option_value;
    }
  });
  if (json) {
    input_field.value += "}";
  }
  if (trigger) {
    $(input_field).trigger('change');
  }
}

function update_placeholder(selected_items, option) {

  let input_field = selected_items.parentElement.querySelector(".select7_input");
  let json = input_field.getAttribute("format") == "json";

  selected_items.innerHTML += "<div draggable='true' class='select7_item'> \
                                " + (json ? "<input class='select7_spinner' min='-10' max='10' step='1' type='number' value='" +
      option.getAttribute("json_value") + "'> " : "") + " \
                                <div class='select7_del'>\
                                  <div class='select7_x'></div>\
                                  <div class='select7_x'></div>\
                                </div>\
                                <div data-option-value='"+ option.getAttribute("value")
    + "' class='select7_content'>" + option.innerText + "</div>\
                              </div> ";

  update_items_events(selected_items);
}

function update_after_drag_drop(selected_items) {
  let select = selected_items.parentElement.querySelector(".select7_select");
  update_input_field(select, true);
  update_items_events(selected_items);
}

function update_items_events(selected_items) {

  let spinners = selected_items.getElementsByClassName("select7_spinner");
  for (let x = 0; x < spinners.length; x++) {
    let spinner = spinners[x];
    spinner.oninput = update_spinner_val;
  }

  let del_buttons = selected_items.getElementsByClassName("select7_del");
  for (let x = 0; x < del_buttons.length; x++) {
    let del_button = del_buttons[x];
    del_button.onclick = function () { Select7.remove(this, event) };
  }

  add_drag_events(selected_items, update_after_drag_drop);
}


function update_spinner_val() {
  this.setAttribute("value", this.value);
  let select = this.parentElement.parentElement.parentElement.getElementsByTagName("select")[0];
  update_input_field(select, false)
}

$(document).ready(function () {
  let selects_containers = $(".select7_container");
  for (let select_container of selects_containers) {
    let select = select_container.getElementsByTagName("select")[0];
    let selected_items = select_container.querySelector(".select7_items");
    let input_field = select_container.querySelector(".select7_input");
    let json = input_field.getAttribute("format") == "json";

    select.onchange = function () { Select7.add(this, event) };
    // select.innerHTML = "<option value='' class='select7_hide' disabled></option>" + select.innerHTML;
    select.value = ''; // reset select options to enable next user select
    //let input = document.createRange().createContextualFragment('<input class="select7_input auto-submit-item" name="'+ select.name +'" type="hidden">');
    //select_container.appendChild(input);
    $(select).removeAttr("name");

    const children = [...select.getElementsByTagName('option')]
    if (json && !input_field.value.startsWith("{{")) {
      let json_data = JSON.parse(input_field.value);
      for (let score in json_data) {
        children.forEach(function (option) {
          if (option.value != "" && score == option.value) {
            option.setAttribute("selected", "selected");
            option.setAttribute("json_value", json_data[score]);
            update_placeholder(selected_items, option);
          }
        });
      }
      update_input_field(select, false);

    } else {
      const selected_fields = [...input_field.value.split(";")];
      selected_fields.forEach(function (selected_field) {
        children.forEach(function (option) {
          if (option.value != "" && selected_field == option.value) {
            option.setAttribute("selected", "selected");

            // let placeholder = option.parentElement.parentElement.querySelector(".select7_placeholder");
            // placeholder.style.display = "none";

            update_placeholder(selected_items, option);
          }
        });
      });
      update_input_field(select, false);
    }
  }
});


const Select7 = {};

Select7.add = (elem, e) => {
  e.stopPropagation();

  let option_text = elem[elem.selectedIndex].text;
  let option_value = elem[elem.selectedIndex].value;
  let selected_items = elem.parentElement.querySelector(".select7_items");
  if (option_value === "" && option_text === "")
    return;
  if ($(selected_items).find(`[data-option-value="${option_value}"]`)[0])
    return;

  // let placeholder = elem.parentElement.querySelector(".select7_placeholder");
  // placeholder.style.display = "none";
  update_placeholder(selected_items, elem[elem.selectedIndex]);

  elem[elem.selectedIndex].setAttribute("selected", "");

  update_input_field(elem, true);
  //elem[elem.selectedIndex].parentElement.removeChild(elem[elem.selectedIndex]);
  //if (elem.length == 1)
  //elem.style.display = "none";
};

Select7.remove = (elem, e) => {
  e.stopPropagation();
  let select = elem.parentElement.parentElement.parentElement.querySelector(".select7_select");
  select.value = ''; // reset select options to enable next user select
  let option_text = elem.parentElement.querySelector(".select7_content").innerHTML;
  let option_value = elem.parentElement.querySelector(".select7_content").dataset.optionValue;
  let selector = elem.parentElement.parentElement.parentElement.querySelector(".select7_select");

  //selector.innerHTML += "<option value='"+ option_value +"'>"+ option_text +"</option>";
  $(selector).find(`[value="${option_value}"]`).removeAttr("selected");

  //if (selector.length > 1)
  //selector.style.display = "block";

  // let selected_items = elem.parentElement.parentElement.parentElement.querySelectorAll(".select7_item");
  // if (selected_items.length == 1) {
  //     let placeholder = elem.parentElement.parentElement.parentElement.querySelector(".select7_placeholder");
  // placeholder.style.display = "block";
  // }

  elem.parentElement.parentElement.removeChild(elem.parentElement);

  update_input_field(select, true);
};
