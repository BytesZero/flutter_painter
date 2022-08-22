import 'dart:html';

// 右键菜单
_preventContextMenu(Event event) => {
      event.preventDefault(),
    };

/// 禁用右键菜单
void disableRightClick() {
  document.addEventListener('contextmenu', _preventContextMenu);
}

/// 启用右键菜单
void enableRightClick() {
  document.removeEventListener('contextmenu', _preventContextMenu);
}
