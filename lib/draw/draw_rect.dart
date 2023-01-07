import '../common/copyable.dart';
import 'base_draw.dart';

/// 绘制矩形
class DrawRect extends BaseDraw implements Copyable<DrawRect> {
  //线宽
  double lineWidth = 4;

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
    Rect rect = Rect.fromLTWH(
      offset.dx,
      offset.dy,
      drawSize?.width ?? 20,
      drawSize?.height ?? 20,
    );
    canvas.drawRect(rect, paint);
  }

  @override
  DrawRect copy() {
    var newCopy = DrawRect()..lineWidth = lineWidth;
    super.copyBaseDraw(newCopy);
    return newCopy;
  }
}
