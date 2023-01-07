import '../common/copyable.dart';
import 'base_draw.dart';
import 'draw_shape.dart';

/// 绘制椭圆形
class DrawShapeOval extends BaseShape
    implements Copyable<DrawShapeOval> {
  @override
  void drawShape(Canvas canvas, Size size) {
    canvas.drawOval(rect!, paint);
  }

  @override
  DrawShapeOval copy() {
    var newCopy = DrawShapeOval();
    super.copyBaseShape(newCopy);
    return newCopy;
  }
}
