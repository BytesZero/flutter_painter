import '../common/copyable.dart';
import 'base_draw.dart';
import 'draw_shape.dart';

/// 绘制波浪线
class DrawShapeWavyLine extends BaseShape
    implements Copyable<DrawShapeWavyLine> {
  @override
  void drawShape(Canvas canvas, Size size) {
    // 波浪高度
    double wavyHeight = lineWidth * 4;
    // 设置路径
    Path path = Path()
      ..moveTo(offset.dx, offset.dy)
      ..lineTo(rect!.bottomRight.dx, rect!.bottomRight.dy);
    // 对角线距离，线长
    // double lineLength =
    //     math.sqrt(math.pow(rect!.width, 2) + math.pow(rect!.height, 2));
    // // 夹角角度
    // double angle = math.atan2(
    //     rect!.bottomRight.dy - offset.dy, rect!.bottomRight.dx - offset.dx);

    // for (var i = 0; i < lineLength / wavyHeight / 2; i++) {
    //   final x2 = offset.dx + wavyHeight * math.cos(angle);
    //   final y2 = offset.dy + wavyHeight * math.sin(angle);
    //   // 绘制贝塞尔曲线
    //   path.quadraticBezierTo(x2 / 4, y2 - wavyHeight, x2 / 2, y2);
    //   path.quadraticBezierTo(x2 - (x2 / 4), y2 + wavyHeight, x2, y2);
    // }
    // 绘制路径
    canvas.drawPath(path, paint);
  }

  @override
  DrawShapeWavyLine copy() {
    var newCopy = DrawShapeWavyLine();
    super.copyBaseShape(newCopy);
    return newCopy;
  }
}
