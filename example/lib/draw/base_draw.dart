import 'package:flutter/rendering.dart';

abstract class BaseDraw {
  Offset offset; // 位置
  Size size; // 大小
  Paint paint = Paint(); // 画笔

  /// 绘制
  /// [canvas] 画板
  /// [size] 大小
  void draw(Canvas canvas, Size size);
}
