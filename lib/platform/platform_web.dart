import 'dart:html';

void disableRightClick() {
  document.onContextMenu.listen((e) {
    e.preventDefault();
  });
}
