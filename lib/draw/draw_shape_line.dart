import '../common/copyable.dart';
import 'base_draw.dart';
import 'draw_shape.dart';

/// 绘制形状线
class DrawShapeLine extends BaseShape implements Copyable<DrawShapeLine> {
  @override
  void drawShape(Canvas canvas, Size size) {
    canvas.drawLine(offset, rect!.bottomRight, paint);
  }

  @override
  DrawShapeLine copy() {
    var newCopy = DrawShapeLine();
    super.copyBaseShape(newCopy);
    return newCopy;
  }
}
