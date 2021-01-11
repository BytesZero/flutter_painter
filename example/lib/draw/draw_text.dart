import 'package:flutter/gestures.dart';

import 'base_draw.dart';

/// 绘制文字
class DrawText extends BaseDraw {
  String text; // 文字
  Color color = Color(0xFFFFFFFF); // 颜色
  double fontSize = 14; // 文字大小

  @override
  void draw(Canvas canvas, Size size) {
    if (text?.isEmpty ?? true) {
      return;
    }
    // 设置央视
    TextStyle style = TextStyle(fontSize: fontSize, color: color);
    // 设置问绷
    TextSpan textSpan = TextSpan(text: text, style: style,recognizer: ForcePressGestureRecognizer());
    // 设置文本画笔
    TextPainter tp =
        TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    tp.layout(minWidth: 20.0, maxWidth: size.width);
    tp.paint(canvas, offset);
  }
}
