import 'base_draw.dart';

/// 绘制线
class DrawLine extends BaseDraw {
  Color color = Color(0xFFFFFFFF); // 颜色
  double lineWidth = 4; //线宽
  List<Offset> linePath = []; // 绘制线的点的集合

  @override
  void draw(Canvas canvas, Size size) {
    // 设置画笔
    paint
      ..isAntiAlias = true
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = lineWidth;
    // 绘制涂鸦
    for (int i = 0; i < linePath.length - 1; i++) {
      if (linePath[i] != null && linePath[i + 1] != null) {
        // 绘制线
        canvas.drawLine(linePath[i], linePath[i + 1], paint);
      }
    }
  }
}
