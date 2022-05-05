import 'base_draw.dart';

export 'package:flutter/rendering.dart';

// 绘制线基类
abstract class BaseLine extends BaseDraw {
  // 绘制线的点的集合
  List<Offset> linePath = [];
  //线宽
  double lineWidth = 4;

  /// 绘制
  /// [canvas] 画板
  /// [size] 大小
  @override
  void draw(Canvas canvas, Size size);
}
