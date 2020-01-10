

var dragSrcEl = null;

function handleDragStart(e) {
  this.style.opacity = '0.4';  // this / e.target is the source node.

  dragSrcEl = this;

  e.dataTransfer.effectAllowed = 'move';
  e.dataTransfer.setData('text/html', this.innerHTML);
}

function handleDragOver(e) {
  if (e.preventDefault) {
    e.preventDefault(); // Necessary. Allows us to drop.
  }

  e.dataTransfer.dropEffect = 'move';  // See the section on the DataTransfer object.

  return false;
}

function handleDragEnter(e) {
  // this / e.target is the current hover target.
  // this.classList.add('over');
}

function handleDragLeave(e) {
  // this.classList.remove('over');  // this / e.target is previous target element.
}

function handleDrop(e) {
  // this/e.target is current target element.

  if (e.stopPropagation) {
    e.stopPropagation(); // Stops some browsers from redirecting.
  }

  // Don't do anything if dropping the same column we're dragging.
  if (dragSrcEl != this && dragSrcEl.parentElement == this.parentElement) {
    // Set the source column's HTML to the HTML of the column we dropped on.
    dragSrcEl.innerHTML = this.innerHTML;
    this.innerHTML = e.dataTransfer.getData('text/html');

    // update_after_drag_drop(this.parentElement);
  }

  return false;
}

function handleDragEnd(e) {
  // this/e.target is the source node.
  this.style.opacity = '1';
  // [].forEach.call(cols, function (col) {
  //   col.classList.remove('over');
  // });
}

window.add_drag_events = function (draggable_container, fun_on_drop) {
  var draggables = draggable_container.querySelectorAll('[draggable]');
  [].forEach.call(draggables, function (draggable) {
    draggable.addEventListener('dragstart', handleDragStart, false);
    // draggable.addEventListener('dragenter', handleDragEnter, false);
    draggable.addEventListener('dragover', handleDragOver, false);
    // draggable.addEventListener('dragleave', handleDragLeave, false);
    // draggable.addEventListener('drop', function(e){handleDrop(e, this, fun_on_drop)}, false);
    draggable.addEventListener('drop', handleDrop, false);
    draggable.addEventListener('dragend', handleDragEnd, false);

    draggable.ondrop = function () { fun_on_drop(this.parentElement) };
  });
}
