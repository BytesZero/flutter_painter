import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'draw/draw_borad.dart';
import 'draw/draw_line.dart';
import 'draw/base_draw.dart';
import 'draw/draw_text.dart';

/// Flutter Painter
class FlutterPainterWidget extends StatefulWidget {
  FlutterPainterWidget(
      {Key key,
      @required this.background,
      this.width,
      this.height,
      this.brushWidth = 2,
      this.brushColor = Colors.red,
      this.onTapText})
      : super(key: key);
  final Widget background;
  final double width;
  final double height;
  final Color brushColor;
  final double brushWidth;
  final ValueChanged<DrawText> onTapText;

  @override
  FlutterPainterWidgetState createState() => FlutterPainterWidgetState();
}

class FlutterPainterWidgetState extends State<FlutterPainterWidget>
    with AutomaticKeepAliveClientMixin {
  // 绘制转成图片的 key
  GlobalKey _drawToImageKey = GlobalKey();

  /// 默认缩放信息
  double _scale = 1.0;
  double _tmpScale = 1.0;
  double _moveX = 0.0;
  double _tmpMoveX = 0.0;
  double _moveY = 0.0;
  double _tmpMoveY = 0.0;
  double _rotation = 0.0;
  Offset _tmpFocal = Offset.zero;

  /// 是否被 90度的奇数，就是90和270
  bool get is90 => (_rotation ~/ (pi / 2)).isOdd;

  /// 矩阵信息
  Matrix4 _matrix4;

  // 按下手指个数
  int _pointerCount = 0;
  int get pointerCount => _pointerCount;
  // 画板模式
  BoradMode _boradMode = BoradMode.Zoom;
  BoradMode get boradMode => _boradMode;

  // 绘制集合
  List<BaseDraw> paintList = [];
  // 临时线
  DrawLine _tempLine;
  // 临时文字，标记选中赋值
  DrawText _tempText;
  // 临时按下事件记录，防止事件错乱
  TapDownDetails _tempTapDownDetails;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _matrix4 = Matrix4.identity()
      ..scale(_scale, _scale)
      ..translate(_moveX, _moveY);
    return Scaffold(
      body: Container(
        child: RepaintBoundary(
          key: _drawToImageKey,
          child: Transform(
            transform: _matrix4,
            alignment: FractionalOffset.center,
            child: Stack(
              children: [
                Transform.rotate(
                  angle: _rotation,
                  child: widget.background,
                ),
                CustomPaint(
                  size: Size.infinite,
                  painter: DrawBorad(paintList: paintList),
                  child: Listener(
                      onPointerDown: (event) {
                        _pointerCount++;
                        debugPrint('onPointerDown pointerCount:$_pointerCount');
                        switchBoradMode();
                      },
                      onPointerUp: (event) {
                        _pointerCount--;
                        debugPrint(
                            'onPointerCancel pointerCount:$_pointerCount');
                        switchBoradMode();
                      },
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) {
                          debugPrint('onTapDown');
                          // 设置按下事件信息
                          _tempTapDownDetails = details;
                          _handleOnPanStart(details.localPosition);
                        },
                        onTap: () {
                          debugPrint('onTap');
                          _handleOnTap();
                        },
                        onScaleStart: (details) {
                          debugPrint('onScaleStart');
                          if (boradMode == BoradMode.Zoom ||
                              boradMode == BoradMode.Edit) {
                            _handleOnScaleStart(details);
                          } else {
                            _handleOnPanUpdate(details.localFocalPoint);
                          }
                        },
                        onScaleUpdate: (details) {
                          debugPrint('onScaleUpdate');
                          if (boradMode == BoradMode.Zoom ||
                              boradMode == BoradMode.Edit) {
                            _handleOnScaleUpdate(details);
                          } else {
                            _handleOnPanUpdate(details.localFocalPoint);
                          }
                        },
                        onScaleEnd: (details) {
                          debugPrint('onScaleEnd');
                          _tempLine = null;
                        },
                      )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 切换画板模式
  void switchBoradMode() {
    if (_boradMode != BoradMode.Edit) {
      if (_pointerCount > 1) {
        _boradMode = BoradMode.Zoom;
      } else {
        _boradMode = BoradMode.Draw;
      }
      setState(() {});
    }
  }

  /// 处理点击事件
  void _handleOnTap() {
    Offset lp = _tempTapDownDetails.localPosition;
    debugPrint('onTapDown details:${lp.toString()}');
    debugPrint('onTapDown _tempText:${_tempText.toString()}');
    if (_tempText != null) {
      /// 计算是否命中删除区域
      double delRadius = _tempText.delRadius;
      Rect tempTextRect = _tempText.textRect;
      if (_tempText.selected &&
          lp.dx >= (tempTextRect.left - delRadius) &&
          lp.dx <= (tempTextRect.left + delRadius) &&
          lp.dy >= (tempTextRect.top - delRadius) &&
          lp.dy <= (tempTextRect.top + delRadius)) {
        paintList.remove(_tempText);
        _tempText = null;
        _boradMode = BoradMode.Draw;
        setState(() {});
        return;
      }
    }

    /// 只获取文字
    var textList = paintList.whereType<DrawText>();
    // 遍历查看是否命中事件
    for (var item in textList) {
      Rect textRect = item.textRect;
      debugPrint(
          'onTapDown lp:${lp.toString()} textRect:${textRect.toString()} scale:${item.scale}');
      //计算是否命中事件
      if (lp.dx >= textRect.left &&
          lp.dx <= textRect.right &&
          lp.dy >= textRect.top &&
          lp.dy <= textRect.bottom) {
        debugPrint('onTapDown 命中🎯');

        // 命中的是上次命中的，那么触发编辑
        if (item.selected) {
          if (widget.onTapText != null) {
            widget.onTapText(item);
          }
        } else {
          // 先设置为不选中状态
          _tempText?.selected = false;
          // 然后赋值设置为选中状态
          _tempText = item;
          _tempText.selected = true;
          _boradMode = BoradMode.Edit;
          setState(() {});
        }
        break;
      } else {
        debugPrint('onTapDown 未命中');
        item.selected = false;
        _tempText = null;
        _boradMode = BoradMode.Draw;
        setState(() {});
      }
    }
  }

  /// 处理缩放移动开始事件
  void _handleOnScaleStart(ScaleStartDetails details) {
    _tmpFocal = details.focalPoint;

    /// 有选中文字处理选中文字
    if (_tempText != null && _tempText.selected) {
      _tmpMoveX = _tempText.offset.dx;
      _tmpMoveY = _tempText.offset.dy;
      _tmpScale = _tempText.scale;
    } else {
      _tmpMoveX = _moveX;
      _tmpMoveY = _moveY;
      _tmpScale = _scale;
      // _tmpRotation = _rotation;
    }
  }

  /// 处理缩放移动更新事件
  void _handleOnScaleUpdate(ScaleUpdateDetails details) {
    /// 有选中文字处理选中文字
    if (_tempText != null && _tempText.selected) {
      double textMoveX = _tmpMoveX + (details.focalPoint.dx - _tmpFocal.dx);
      double textMoveY = _tmpMoveY + (details.focalPoint.dy - _tmpFocal.dy);
      _tempText.offset = Offset(textMoveX, textMoveY);
      _tempText.scale = _tmpScale * details.scale;
    } else {
      _moveX = _tmpMoveX + (details.focalPoint.dx - _tmpFocal.dx) / _tmpScale;
      _moveY = _tmpMoveY + (details.focalPoint.dy - _tmpFocal.dy) / _tmpScale;
      _scale = _tmpScale * details.scale;
      // _rotation = _tmpRotation + details.rotation;
    }

    setState(() {});
  }

  /// 处理滑动开始事件
  void _handleOnPanStart(Offset point) {
    _tempLine = DrawLine()
      ..color = widget.brushColor
      ..lineWidth = widget.brushWidth;
    _tempLine.linePath.add(point);
    paintList.add(_tempLine);
  }

  /// 处理滑动更新事件
  void _handleOnPanUpdate(Offset point) {
    if (_tempLine == null) {
      _handleOnPanStart(point);
    }
    _tempLine.linePath.add(point);
    paintList.last = _tempLine;
    setState(() {});

    /// 这里是计算区域的算法
    // Offset point = details.localFocalPoint;
    // Size size = Size(widget.width, widget.height);
    // if (_rotation % (pi / 2) == 0) {
    //   size = Size(widget.height, widget.width);
    // }
    // RenderBox referenceBox = context.findRenderObject();
    // Offset point = referenceBox.globalToLocal(details.globalPosition);
    // Offset point = details.localPosition;
    // if (point.dx >= 0 &&
    //     point.dx <= size.width &&
    //     point.dy >= 0 &&
    //     point.dy <= size.height) {
    // } else {
    //   _tempLine = null;
    //   setState(() {});
    // }
  }

  /// 添加线
  void addLine(DrawLine line) {
    paintList.add(line);
    setState(() {});
  }

  /// 添加文字
  void addText(DrawText text) {
    paintList.add(text);
    setState(() {});
  }

  /// 设置旋转角度
  /// // _scale = 1.0;
  // _rotation = _rotation - pi / 2;
  void setRotation(double rotation) {
    _scale = 1.0;
    _rotation = rotation;
    setState(() {});
  }

  /// 回退
  void undo() {
    if (paintList.isNotEmpty) {
      paintList.removeLast();
      setState(() {});
    }
  }

  /// 清空
  void clearDraw() {
    paintList = [];
    setState(() {});
  }

  // 获取为图片
  Future<Uint8List> getImage() async {
    /// 恢复到默认状态
    _scale = 1.0;
    _moveX = 0;
    _moveY = 0;
    setState(() {});
    await Future.delayed(Duration(milliseconds: 300));

    /// 开始保存图片
    RenderRepaintBoundary boundary =
        _drawToImageKey.currentContext.findRenderObject();
    ui.Image image = await boundary.toImage(pixelRatio: 3);
    ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData.buffer.asUint8List();
    print(pngBytes.length);
    return pngBytes;
  }
}
