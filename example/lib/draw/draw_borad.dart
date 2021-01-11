import 'package:flutter/rendering.dart';
import 'base_draw.dart';

/// 画板
class DrawBorad extends CustomPainter {
  DrawBorad({this.paintList});

  List<BaseDraw> paintList = [];

  @override
  void paint(Canvas canvas, Size size) {
    for (var draw in paintList) {
      draw.draw(canvas, size);
    }
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
}
