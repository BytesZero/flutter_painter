import 'dart:ui';

import '../common/copyable.dart';
import 'base_draw.dart';
import 'draw_edit.dart';

/// 绘制图片
class DrawImage extends BaseDraw with DrawEdit implements Copyable<DrawImage> {
  Image? image; // 图片

  @override
  void draw(Canvas canvas, Size size) {
    if (image == null) {
      return;
    }
    if (drawSize != null) {
      // 计算绘制矩阵
      rect = Rect.fromLTWH(
        offset.dx,
        offset.dy,
        drawSize!.width * this.scale,
        drawSize!.height * this.scale,
      );
    } else {
      // 计算绘制矩阵
      rect = Rect.fromLTWH(
        offset.dx,
        offset.dy,
        image!.width.toDouble() * this.scale,
        image!.height.toDouble() * this.scale,
      );
    }
    // 指定大小绘制
    canvas.drawImageRect(
      image!,
      Rect.fromLTWH(0, 0, image!.width.toDouble(), image!.height.toDouble()),
      rect!,
      paint,
    );
    // 绘制外围辅助线条
    // canvas.drawRect(
    //   rect,
    //   paint
    //     ..color = Color(0xff2233ff)
    //     ..style = PaintingStyle.stroke
    //     ..strokeWidth = 4,
    // );
    // 绘制编辑
    drawEdit(canvas, paint);
  }

  @override
  DrawImage copy() {
    var newCopy = DrawImage()..image = image;
    super.copyBaseDraw(newCopy);
    super.copyEdit(newCopy);
    return newCopy;
  }
}
