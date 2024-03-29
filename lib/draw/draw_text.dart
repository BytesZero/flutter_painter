import '../common/copyable.dart';
import 'base_draw.dart';
import 'draw_edit.dart';

/// 绘制文字
class DrawText extends BaseDraw with DrawEdit implements Copyable<DrawText> {
  String? text; // 文字
  Color color = Color(0xFFFFFFFF); // 颜色
  double fontSize = 14; // 文字大小
  String? fontFamily; // 字体
  TextStyle? style; // 文字样式
  late TextPainter tp; // 文字画笔

  @override
  void draw(Canvas canvas, Size size) {
    if (text?.isEmpty ?? true) {
      return;
    }
    canvas.save();
    // 设置样式
    TextStyle newStyle = style ??
        TextStyle(
          fontSize: fontSize,
          color: color,
          fontFamily: fontFamily,
        );
    // 设置文本
    TextSpan textSpan = TextSpan(
      text: text,
      style: newStyle,
    );
    // 设置文本画笔
    tp = TextPainter(
      text: textSpan,
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
      textScaleFactor: scale,
    );
    // 布局文字
    tp.layout(maxWidth: drawSize?.width ?? double.infinity);
    // 计算文字矩阵
    this.rect = Rect.fromLTWH(
      offset.dx - 4,
      offset.dy - 4,
      tp.width + 8,
      tp.height + 8,
    );
    // 绘制文字
    tp.paint(canvas, offset);
    // 绘制编辑
    drawEdit(canvas, paint);
    // 回退
    canvas.restore();
  }

  @override
  DrawText copy() {
    var newCopy = DrawText()
      ..text = text
      ..color = color
      ..fontSize = fontSize
      ..fontFamily = fontFamily
      ..style = style;
    super.copyBaseDraw(newCopy);
    super.copyEdit(newCopy);
    return newCopy;
  }
}
