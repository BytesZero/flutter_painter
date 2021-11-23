import 'base_draw.dart';
import 'draw_edit.dart';

/// 绘制文字
class DrawText extends BaseDraw with DrawEdit {
  String text; // 文字
  Color color = Color(0xFFFFFFFF); // 颜色
  double fontSize = 14; // 文字大小
  TextPainter tp; // 文字画笔

  @override
  void draw(Canvas canvas, Size size) {
    if (text?.isEmpty ?? true) {
      return;
    }
    canvas.save();

    // 设置样式
    TextStyle style = TextStyle(fontSize: fontSize * scale, color: color);
    // 设置文本
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
}
