import 'base_draw.dart';

/// 绘制形状
abstract class BaseShape extends BaseDraw {
  //线宽
  double lineWidth = 4;
  // 矩形
  Rect? rect;

  @override
  void draw(Canvas canvas, Size size) {
    // 设置画笔
    paint
      ..isAntiAlias = true
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = lineWidth;
    // 绘制矩形大小
    rect = Rect.fromLTWH(
      offset.dx,
      offset.dy,
      drawSize?.width ?? 20,
      drawSize?.height ?? 20,
    );
    // 绘制形状
    drawShape(canvas, size);
    // canvas.drawRect(rect, paint);

    // canvas.drawOval(rect, paint);
    // canvas.drawLine(offset, rect.bottomRight, paint);
    // Path path = Path()
    //   ..moveTo(rect.bottomLeft.dx, rect.bottomLeft.dy)
    //   ..lineTo(rect.topCenter.dx, rect.topCenter.dy)
    //   ..lineTo(rect.bottomRight.dx, rect.bottomRight.dy)
    //   ..close();
    // canvas.drawPath(path, paint);
  }

  /// 绘制形状
  void drawShape(Canvas canvas, Size size) {}

  /// 复制新对象
  BaseShape copyBaseShape(BaseShape shape) {
    var newCopy = shape..lineWidth = lineWidth;
    super.copyBaseDraw(newCopy);
    return newCopy;
  }
}
