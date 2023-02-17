import 'dart:math' as math;

import '../common/copyable.dart';
import 'base_draw.dart';
import 'draw_shape.dart';

/// 绘制形状直线箭头
class DrawShapeLineArrow extends BaseShape
    implements Copyable<DrawShapeLineArrow> {
  @override
  void drawShape(Canvas canvas, Size size) {
    Offset p2 = rect!.bottomRight;
    double absDx = p2.dx - offset.dx;
    double absDy = p2.dy - offset.dy;
    // 箭头大小
    double arrowSize = lineWidth * 2;
    // 判断最短距离
    if (absDx.abs() < arrowSize && absDy.abs() < arrowSize) {
      return;
    }
    // 绘制直线
    canvas.drawLine(offset, p2, paint);
    // 计算角度
    final angle = math.atan2(p2.dy - offset.dy, p2.dx - offset.dx);
    // 计算箭头角度
    final arrowAngle = 20 * math.pi / 180;
    final path = Path();
    // 移动到下部箭头端位置
    path.moveTo(p2.dx - arrowSize * math.cos(angle - arrowAngle),
        p2.dy - arrowSize * math.sin(angle - arrowAngle));
    // 移动到箭头端位置
    path.lineTo(p2.dx, p2.dy);
    // 移动到上部箭头端位置
    path.lineTo(p2.dx - arrowSize * math.cos(angle + arrowAngle),
        p2.dy - arrowSize * math.sin(angle + arrowAngle));
    // 闭合
    path.close();
    // 绘制箭头
    canvas.drawPath(path, paint);
  }

  @override
  DrawShapeLineArrow copy() {
    var newCopy = DrawShapeLineArrow();
    super.copyBaseShape(newCopy);
    return newCopy;
  }
}
