import 'package:flutter/rendering.dart';
export 'package:flutter/rendering.dart';

// 绘制基类
abstract class BaseDraw {
  Offset offset; // 位置
  Size drawSize; // 绘制项大小
  Paint paint = Paint(); // 画笔

  /// 绘制
  /// [canvas] 画板
  /// [size] 大小
  void draw(Canvas canvas, Size size);
}
