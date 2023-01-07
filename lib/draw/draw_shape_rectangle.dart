import '../common/copyable.dart';
import 'base_draw.dart';
import 'draw_shape.dart';

/// 绘制矩形
class DrawShapeRectangle extends BaseShape
    implements Copyable<DrawShapeRectangle> {
  @override
  void drawShape(Canvas canvas, Size size) {
    canvas.drawRect(rect!, paint);
    // canvas.drawOval(rect, paint);
    // canvas.drawLine(offset, rect.bottomRight, paint);
    // Path path = Path()
    //   ..moveTo(rect.bottomLeft.dx, rect.bottomLeft.dy)
    //   ..lineTo(rect.topCenter.dx, rect.topCenter.dy)
    //   ..lineTo(rect.bottomRight.dx, rect.bottomRight.dy)
    //   ..close();
    // canvas.drawPath(path, paint);
  }

  @override
  DrawShapeRectangle copy() {
    var newCopy = DrawShapeRectangle();
    super.copyBaseShape(newCopy);
    return newCopy;
  }
}
