import 'dart:ui';

import 'base_draw.dart';

/// 绘制线
class DrawLine extends BaseDraw {
  Color color = Color(0xFFFFFFFF); // 颜色
  double lineWidth = 4; //线宽
  Path path = Path(); // 路径
  List<Offset> linePath = []; // 绘制线的点的集合

  @override
  void draw(Canvas canvas, Size size) {
    paint
      ..isAntiAlias = true
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = lineWidth;
    for (int i = 0; i < linePath.length - 1; i++) {
      if (linePath[i] != null && linePath[i + 1] != null) {
        // 绘制线
        canvas.drawLine(linePath[i], linePath[i + 1], paint);
      }
    }
  }
}
