import 'package:flutter/rendering.dart';

export 'package:flutter/rendering.dart';

// 绘制基类
abstract class BaseDraw {
  Offset offset = Offset.zero; // 位置
  Size? drawSize; // 绘制项大小
  Paint paint = Paint(); // 画笔
  bool clickAdd = false; // 点击添加

  /// 绘制
  /// [canvas] 画板
  /// [size] 大小
  void draw(Canvas canvas, Size size);

  /// 拷贝现对象属性到新对象上
  /// [newDraw] 新对象
  BaseDraw copyBaseDraw(BaseDraw newDraw) {
    newDraw
      ..offset = offset
      ..drawSize = drawSize
      ..clickAdd = clickAdd;
    return newDraw;
  }
}
