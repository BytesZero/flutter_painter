import '../common/copyable.dart';
import 'base_draw.dart';
import 'draw_shape.dart';

/// 绘制三角形
class DrawShapeTriangle extends BaseShape
    implements Copyable<DrawShapeTriangle> {
  @override
  void drawShape(Canvas canvas, Size size) {
    // 设置路径
    Path path = Path()
      ..moveTo(rect!.bottomLeft.dx, rect!.bottomLeft.dy)
      ..lineTo(rect!.topCenter.dx, rect!.topCenter.dy)
      ..lineTo(rect!.bottomRight.dx, rect!.bottomRight.dy)
      ..close();
    // 绘制路径
    canvas.drawPath(path, paint);
  }

  @override
  DrawShapeTriangle copy() {
    var newCopy = DrawShapeTriangle();
    super.copyBaseShape(newCopy);
    return newCopy;
  }
}
