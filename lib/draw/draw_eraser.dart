import 'base_line.dart';

/// 橡皮擦
class DrawEraser extends BaseLine {
  @override
  void draw(Canvas canvas, Size size) {
    // 设置画笔
    paint
      ..blendMode = BlendMode.clear
      ..isAntiAlias = true
      // ..color = Color(0xFF7B7B7B)// 调试使用
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = lineWidth;
    // 绘制橡皮擦线
    // 第一个点
    Offset p0 = linePath[0];
    Path path = Path()..moveTo(p0.dx, p0.dy);
    // 线段数量
    int lineCount = linePath.length;
    // 绘制线
    for (int i = 1; i < lineCount; i++) {
      // 获取前后两个点
      Offset ps = linePath[i];
      path.lineTo(ps.dx, ps.dy);
    }
    // 绘制线
    canvas.drawPath(path, paint);
    // 绘制橡皮擦(测试用)
    // Offset pe = linePath.last;
    // canvas.drawCircle(
    //   Offset(pe.dx, pe.dy),
    //   lineWidth / 2,
    //   paint
    //     ..blendMode = BlendMode.src
    //     ..color = Color(0xFF091BE1)
    //     ..style = PaintingStyle.fill,
    // );
  }
}
