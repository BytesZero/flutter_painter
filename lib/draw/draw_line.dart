import '../common/copyable.dart';
import 'base_line.dart';
import 'draw_edit.dart';

/// 绘制线
class DrawLine extends BaseLine with DrawEdit implements Copyable<DrawLine> {
  Color color = Color(0xFFFFFFFF); // 颜色

  @override
  void draw(Canvas canvas, Size size) {
    if (linePath.length < 2) {
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
    Path path = Path()..moveTo(p0.dx + offset.dx, p0.dy + offset.dy);
    // 线段数量
    int lineCount = linePath.length - 1;
    // 绘制线
    for (int i = 1; i < lineCount; i++) {
      // 获取前后两个点
      Offset ps = linePath[i];
      Offset pe = linePath[i + 1];
      // 计算前后两个点的中心点
      double xc = (ps.dx + pe.dx) / 2;
      double xy = (ps.dy + pe.dy) / 2;
      // 使用二阶贝塞尔曲线生成 path
      path.quadraticBezierTo(
          ps.dx + offset.dx, ps.dy + offset.dy, xc + offset.dx, xy + offset.dy);
      // 添加最后一段 path
      if (i == lineCount - 1) {
        path.lineTo(pe.dx + offset.dx, pe.dy + offset.dy);
      }
    }
    // 绘制线
    canvas.drawPath(path, paint);
    // 绘制编辑
    rect = path.getBounds().inflate(6);
    drawEdit(canvas, paint);
  }

  @override
  DrawLine copy() {
    var newCopy = DrawLine()..color = color;
    super.copyBaseDraw(newCopy);
    super.copyEdit(newCopy);
    return newCopy;
  }
}
