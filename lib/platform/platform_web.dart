import 'dart:html';

/// 禁用右键菜单
void disableRightClick() {
  document.onContextMenu.listen((e) {
    e.preventDefault();
  });
}

/// 启用右键菜单
void enableRightClick() {
  document.onContextMenu.listen((e) {
    e.preventDefault();
  });
}
