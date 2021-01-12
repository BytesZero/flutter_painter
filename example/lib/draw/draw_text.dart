import 'base_draw.dart';

/// 绘制文字
class DrawText extends BaseDraw {
  String text; // 文字
  Color color = Color(0xFFFFFFFF); // 颜色
  double fontSize = 14; // 文字大小
  double scale = 1.0; // 缩放
  TextPainter tp; // 文字画笔
  // 文字矩阵
  Rect get textRect => Rect.fromLTWH(
        offset.dx - 4,
        offset.dy - 4,
        tp.width + 8,
        tp.height + 8,
      );

  // 是否选中
  bool selected = false;
  // 删除半径
  double delRadius = 6;

  @override
  void draw(Canvas canvas, Size size) {
    if (text?.isEmpty ?? true) {
      return;
    }
    canvas.save();
    // 缩放
    canvas.scale(scale);
    // 设置央视
    TextStyle style = TextStyle(fontSize: fontSize, color: color);
    // 设置问绷
    TextSpan textSpan = TextSpan(
      text: text,
      style: style,
    );
    // 设置文本画笔
    tp = TextPainter(
      text: textSpan,
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );
    // 布局文字
    tp.layout(minWidth: drawSize.width, maxWidth: size.width - offset.dx - 4);
    // 绘制文字
    tp.paint(canvas, offset);
    if (selected) {
      /// 设置边框画笔
      paint
        ..color = Color(0xFFFFFFFF)
        ..isAntiAlias = true
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      /// 绘制边框
      canvas.drawRect(
        textRect,
        paint,
      );
      canvas.save();

      /// 设置删除画笔
      paint.style = PaintingStyle.fill;
      //画圆形背景
      canvas.drawCircle(Offset(textRect.left, textRect.top), delRadius, paint);
      // 设置 X 画笔
      paint
        ..style = PaintingStyle.stroke
        ..color = Color(0xFF999999);
      double xRadius = delRadius / 3.0;
      // 画 X
      canvas.drawLine(
        Offset(textRect.left - xRadius, textRect.top - xRadius),
        Offset(textRect.left + xRadius, textRect.top + xRadius),
        paint,
      );
      canvas.drawLine(
        Offset(textRect.left + xRadius, textRect.top - xRadius),
        Offset(textRect.left - xRadius, textRect.top + xRadius),
        paint,
      );
      canvas.restore();
    }
    canvas.restore();
  }
}
