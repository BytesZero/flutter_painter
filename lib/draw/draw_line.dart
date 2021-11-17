import 'base_draw.dart';

/// 绘制线
class DrawLine extends BaseDraw {
  Color color = Color(0xFFFFFFFF); // 颜色
  double lineWidth = 4; //线宽
  List<Offset> linePath = []; // 绘制线的点的集合

  @override
  void draw(Canvas canvas, Size size) {
    if (linePath.isEmpty ?? true) {
      return;
    }
    // 设置画笔
    paint
      ..isAntiAlias = true
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = lineWidth;
    // 第一个点
    Offset p0 = linePath[0];
    Path path = Path()..moveTo(p0.dx, p0.dy);
    // 线段数量
    int lineCount = linePath.length - 1;
    // 绘制线
    for (int i = 1; i < lineCount; i++) {
      // 获取前后两个点
      Offset ps = linePath[i];
      Offset pe = linePath[i + 1];
      // 绘制线（老版本去掉）
      // canvas.drawLine(ps, pe, paint);
      // 计算前后两个点的中心点
      double xc = (ps.dx + pe.dx) / 2;
      double xy = (ps.dy + pe.dy) / 2;
      // 使用二阶贝塞尔曲线生成 path
      path.quadraticBezierTo(ps.dx, ps.dy, xc, xy);
      // 添加最后一段 path
      if (i == lineCount - 1) {
        path.lineTo(pe.dx, pe.dy);
      }
    }

    canvas.drawPath(path, paint);
  }
}
