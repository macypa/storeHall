
function update_input_field(select, trigger) {
  var placeholder = select.parentElement.querySelector(".select7_items");
  var input_field = select.parentElement.parentElement.querySelector(".select7_input");
  input_field.value = "";

  const children = [...placeholder.getElementsByClassName('select7_content')];
  children.forEach(function(option) {
    if (input_field.value == "") {
      input_field.value = option.getAttribute("data-option-value");
    } else {
      input_field.value += ";" + option.getAttribute("data-option-value");
    }
  });
  if (trigger) {
    $(input_field).trigger('change');
  }
}

function update_placeholder(selected_items, option) {

  selected_items.innerHTML += "<div class='select7_item'> \
                                <div data-option-value='"+ option.getAttribute("value") +"' class='select7_content'>"+ option.innerText +"</div>\
                                <div class='select7_del'>\
                                  <div class='select7_x'></div>\
                                  <div class='select7_x'></div>\
                                </div>\
                              </div> ";

  var del_buttons = selected_items.getElementsByClassName("select7_del");
  for( var x = 0; x < del_buttons.length; x++ ){
    var del_button = del_buttons[x];
    del_button.onclick = function(){Select7.remove(this, event)};
  }
}


$( document ).ready(function() {
  var selects_containers = $(".select7_container");
  for (let select_container of selects_containers) {
    var select = select_container.getElementsByTagName("select")[0];
    var input_field = select.parentElement.parentElement.querySelector(".select7_input");
    select.oninput = function(){Select7.add(this, event)};
    select.innerHTML = "<option value='' class='select7_hide'>filler</option>" + select.innerHTML;

    //let input = document.createRange().createContextualFragment('<input class="select7_input auto-submit-item" name="'+ select.name +'" type="hidden">');
    //select_container.appendChild(input);
    $(select).removeAttr("name");

    const children = [...select.getElementsByTagName('option')];
    const selected_fields = [...input_field.value.split(";")];
    selected_fields.forEach(function(selected_field) {
      children.forEach(function(option) {
        if (option.value != "" && selected_field == option.value) {
          option.setAttribute("selected", "selected");

          var placeholder = option.parentElement.parentElement.querySelector(".select7_placeholder");
          placeholder.style.display = "none";

          var selected_items = option.parentElement.parentElement.querySelector(".select7_items");
          update_placeholder(selected_items, option);
        }
      });
    });
    update_input_field(select, false);
  }
});


const Select7 = {};

Select7.add = (elem, e) => {
    e.stopPropagation();

    var option_text =  elem[elem.selectedIndex].text;
    var option_value =  elem[elem.selectedIndex].value;
    var selected_items = elem.parentElement.querySelector(".select7_items");
    var placeholder = elem.parentElement.querySelector(".select7_placeholder");
    if (option_value === "filler" && option_text === "")
      return;
    if ($(selected_items).find(`[data-option-value="${option_value}"]`)[0])
      return;

    placeholder.style.display = "none";
    update_placeholder(selected_items, elem[elem.selectedIndex]);

    elem[elem.selectedIndex].setAttribute("selected", "");

    update_input_field(elem, true);
    //elem[elem.selectedIndex].parentElement.removeChild(elem[elem.selectedIndex]);
    //if (elem.length == 1)
        //elem.style.display = "none";
};

Select7.remove = (elem, e) => {
    e.stopPropagation();
    var select = elem.parentElement.parentElement.parentElement.querySelector(".select7_select");
    var option_text = elem.parentElement.querySelector(".select7_content").innerHTML;
    var option_value = elem.parentElement.querySelector(".select7_content").dataset.optionValue;
    var selector = elem.parentElement.parentElement.parentElement.querySelector(".select7_select");

    //selector.innerHTML += "<option value='"+ option_value +"'>"+ option_text +"</option>";
    $(selector).find(`[value="${option_value}"]`).removeAttr("selected");

    //if (selector.length > 1)
        //selector.style.display = "block";

    var selected_items = elem.parentElement.parentElement.parentElement.querySelectorAll(".select7_item");
    if (selected_items.length == 1) {
        var placeholder = elem.parentElement.parentElement.parentElement.querySelector(".select7_placeholder");
        placeholder.style.display = "block";
    }

    elem.parentElement.parentElement.removeChild(elem.parentElement);

    update_input_field(select, true);
};

Select7.get = (select7_id, type = "both") => {
    var selected_items = document.getElementById(select7_id).querySelectorAll(".select7_content");

    if (selected_items.length > 0) {
        var selected_values = [];

        switch (type) {
            case "value": {
                for (let i = 0; i < selected_items.length; i++)
                    selected_values = [...selected_values, selected_items[i].dataset.optionValue];
                break;
            }
            case "text": {
                for (let i = 0; i < selected_items.length; i++)
                    selected_values = [...selected_values, selected_items[i].innerHTML];
                break;
            }
            case "both": {
                for (let i = 0; i < selected_items.length; i++)
                    selected_values = [...selected_values, {
                        "text": selected_items[i].innerHTML,
                        "value": selected_items[i].dataset.optionValue,
                    }];
                break;
            }
        }

        return selected_values;
    }
};