import 'package:flutter_painter/draw/base_draw.dart';

/// 绘制编辑（选中、移动、缩放、删除）
mixin DrawEdit {
  double scale = 1.0; // 缩放
  bool selected = false; // 是否选中
  double delRadius = 8; // 删除半径
  Rect rect; // 编辑矩阵
  /// 绘制编辑
  void drawEdit(Canvas canvas, Paint paint) {
    if (selected && rect != null) {
      // 设置边框画笔
      paint
        ..color = Color(0xFFDDDDDD)
        ..isAntiAlias = true
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      // 绘制边框
      canvas.drawRect(
        rect,
        paint,
      );
      // 设置删除画笔
      paint
        ..color = Color(0xFFDDDDDD)
        ..style = PaintingStyle.fill;
      //画圆形背景
      canvas.drawCircle(Offset(rect.left, rect.top), delRadius, paint);
      // 设置 X 画笔
      paint
        ..style = PaintingStyle.stroke
        ..color = Color(0xFF999999);
      double xRadius = delRadius / 3.0;
      // 画 X
      canvas.drawLine(
        Offset(rect.left - xRadius, rect.top - xRadius),
        Offset(rect.left + xRadius, rect.top + xRadius),
        paint,
      );
      canvas.drawLine(
        Offset(rect.left + xRadius, rect.top - xRadius),
        Offset(rect.left - xRadius, rect.top + xRadius),
        paint,
      );
    }
  }
}
