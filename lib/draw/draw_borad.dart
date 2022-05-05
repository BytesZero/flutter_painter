import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'base_draw.dart';
import 'draw_edit.dart';

/// 画板
class DrawBorad extends CustomPainter {
  final DrawBoradListenable drawBoradListenable;
  DrawBorad(this.drawBoradListenable) : super(repaint: drawBoradListenable);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.largest, Paint());
    for (var draw in drawBoradListenable.drawList) {
      draw.draw(canvas, size);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DrawBorad oldDelegate) {
    return true;
  }
}

/// 画板模式
enum BoradMode {
  Draw, // 绘制模式
  Zoom, // 缩放模式
  Crop, // 裁剪模式
  Edit, // 编辑模式
}

/// 画板监听器
class DrawBoradListenable extends ChangeNotifier {
  List<BaseDraw> _drawList = [];
  // 获取绘制实体列表
  List<BaseDraw> get drawList => _drawList;

  /// 添加绘制实体
  /// [draw] 绘制实体
  void add(BaseDraw draw) {
    _drawList.add(draw);
    notifyListeners();
  }

  /// 删除绘制实体
  /// [draw] 绘制实体
  void remove(BaseDraw draw) {
    _drawList.remove(draw);
    notifyListeners();
  }

  /// 删除绘制实体
  /// [index] 索引下标
  void removeAt(int index) {
    if (index < _drawList.length) {
      _drawList.removeAt(index);
      notifyListeners();
    } else {
      debugPrint('删除失败，index 无效');
    }
  }

  /// 删除最后一个绘制实体
  BaseDraw? removeLast() {
    if (_drawList.isNotEmpty) {
      BaseDraw lastDraw = _drawList.removeLast();
      notifyListeners();
      return lastDraw;
    }
    return null;
  }

  /// 更新绘制实体
  void update() {
    notifyListeners();
  }

  /// 设置更新最后一个绘制实体
  void setLast(BaseDraw draw) {
    if (_drawList.isNotEmpty) {
      _drawList.last = draw;
      notifyListeners();
    }
  }

  /// 设置编辑实体选中
  void setSelect(DrawEdit? draw, [bool selected = true]) {
    if (draw != null) {
      draw.selected = selected;
      notifyListeners();
    }
  }

  /// 清除所有
  void clear() {
    _drawList = [];
    notifyListeners();
  }
}
