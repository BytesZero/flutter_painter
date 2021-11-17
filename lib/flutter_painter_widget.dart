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
  FlutterPainterWidget({
    Key key,
    @required this.background,
    this.width,
    this.height,
    this.brushColor,
    this.brushWidth,
    this.onTapText,
    this.onPointerCount,
  }) : super(key: key);
  final Widget background;
  final double width;
  final double height;
  // 画笔颜色
  final Color brushColor;
  // 画笔粗细
  final double brushWidth;
  final ValueChanged<DrawText> onTapText;
  final ValueChanged<int> onPointerCount;

  @override
  FlutterPainterWidgetState createState() => FlutterPainterWidgetState();
}

class FlutterPainterWidgetState extends State<FlutterPainterWidget>
    with AutomaticKeepAliveClientMixin {
  // 绘制转成图片的 key
  GlobalKey _drawToImageKey = GlobalKey();

  /// 默认缩放信息
  double _scale = 1.0;
  double get scale => _scale;
  double _bgScale = 1.0;
  double get bgScale => _bgScale;
  double _tmpScale = 1.0;
  double _moveX = 0.0;
  double _tmpMoveX = 0.0;
  double _moveY = 0.0;
  double _tmpMoveY = 0.0;
  // double _rotation = 0.0;
  double _bgRotation = 0.0;
  // 获取旋转角度
  double get backgroundRotation => _bgRotation;
  Offset _tmpFocal = Offset.zero;

  /// 是否被 90度的奇数，就是90和270
  bool get is90 => (_bgRotation ~/ (pi / 2)).isOdd;

  /// 矩阵信息
  Matrix4 _matrix4;
  Matrix4 _bgMatrix4;

  /// 图片矩阵
  Rect imgRect;

  // 按下手指个数
  int _pointerCount = 0;
  int get pointerCount => _pointerCount;
  // 画板模式
  BoradMode _boradMode = BoradMode.Draw;
  BoradMode get boradMode => _boradMode;
  // 画笔颜色
  Color _brushColor = Colors.red;
  // 画笔粗细
  double _brushWidth = 2;

  // 绘制集合
  DrawBoradListenable drawBoradListenable = DrawBoradListenable();
  // 临时线
  DrawLine _tempLine;
  // 临时文字，标记选中赋值
  DrawText _tempText;
  // 临时按下事件记录，防止事件错乱
  TapDownDetails _tempTapDownDetails;

  @override
  void initState() {
    /// 设置默认
    if (widget.brushColor != null) {
      _brushColor = widget.brushColor;
    }
    if (widget.brushWidth != null) {
      _brushWidth = widget.brushWidth;
    }
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _matrix4 = Matrix4.identity()
      ..scale(_scale, _scale)
      ..translate(_moveX, _moveY);
    _bgMatrix4 = Matrix4.identity()
      ..scale(_bgScale, _bgScale)
      ..rotateZ(_bgRotation);
    return Scaffold(
      body: Container(
        child: RepaintBoundary(
          key: _drawToImageKey,
          child: Transform(
            transform: _matrix4,
            alignment: FractionalOffset.center,
            child: Stack(
              children: [
                Transform(
                  transform: _bgMatrix4,
                  alignment: FractionalOffset.center,
                  child: widget.background,
                ),
                RepaintBoundary(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: DrawBorad(drawBoradListenable),
                    child: Listener(
                        onPointerDown: (event) {
                          _pointerCount++;
                          _switchBoradMode();
                        },
                        onPointerUp: (event) {
                          _pointerCount--;

                          /// 注释掉是解决双手放缩放会误触绘制点的问题
                          // _switchBoradMode();
                        },
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (details) {
                            // 设置按下事件信息
                            _tempTapDownDetails = details;
                            if (boradMode == BoradMode.Draw) {
                              _handleOnPanStart(details.localPosition);
                            }
                          },
                          onTapUp: (details) {
                            /// 这里是解决点击后再绘制会从点击的那个点开始绘制的问题，最终效果是多出一段距离来
                            _tempLine = null;
                          },
                          onTap: () {
                            _handleOnTap();
                          },
                          onScaleStart: (details) {
                            if (boradMode == BoradMode.Zoom ||
                                boradMode == BoradMode.Edit) {
                              _handleOnScaleStart(details);
                            } else {
                              _handleOnPanUpdate(details.localFocalPoint);
                            }
                          },
                          onScaleUpdate: (details) {
                            if (boradMode == BoradMode.Zoom ||
                                boradMode == BoradMode.Edit) {
                              _handleOnScaleUpdate(details);
                            } else {
                              _handleOnPanUpdate(details.localFocalPoint);
                            }
                          },
                          onScaleEnd: (details) {
                            _tempLine = null;
                          },
                        )),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 设置画板模式
  Future<void> setBoradMode(BoradMode mode) async {
    _boradMode = mode;
    // 不是编辑模式设置空
    if (mode != BoradMode.Edit && _tempText != null) {
      _tempText.selected = false;
      _tempText = null;
    }
    setState(() {});
  }

  /// 切换画板模式
  void _switchBoradMode() {
    if (_boradMode != BoradMode.Edit) {
      if (_pointerCount > 1) {
        _boradMode = BoradMode.Zoom;
      } else {
        _boradMode = BoradMode.Draw;
      }
      setState(() {});
    }

    /// 返回按下手指数
    if (widget.onPointerCount != null) {
      widget.onPointerCount(_pointerCount);
    }
  }

  /// 处理点击事件
  void _handleOnTap() {
    Offset lp = _tempTapDownDetails.localPosition;
    if (_tempText != null) {
      /// 计算是否命中删除区域
      double delRadius = _tempText.delRadius;
      Rect tempTextRect = _tempText.textRect;
      Rect delRect = Rect.fromCircle(
        center: tempTextRect.topLeft,
        radius: delRadius,
      );
      if (_tempText.selected && delRect.contains(lp)) {
        drawBoradListenable.remove(_tempText);
        _tempText = null;
        _boradMode = BoradMode.Draw;
        setState(() {});
        return;
      }
    }

    /// 只获取文字
    var textList = drawBoradListenable.drawList.whereType<DrawText>();
    // 遍历查看是否命中事件
    for (var item in textList) {
      Rect textRect = item.textRect;

      //计算是否命中事件
      if (textRect.contains(lp)) {
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
      _tmpMoveX = is90 ? _moveY : _moveX;
      _tmpMoveY = is90 ? _moveX : _moveY;
      _tmpScale = _scale;
    }
  }

  /// 处理缩放移动更新事件
  void _handleOnScaleUpdate(ScaleUpdateDetails details) {
    /// 计算运动距离
    double focalMoveX = (details.focalPoint.dx - _tmpFocal.dx);
    double focalMoveY = (details.focalPoint.dy - _tmpFocal.dy);
    double scale = _tmpScale * details.scale;

    /// 有选中文字处理选中文字
    if (_tempText != null && _tempText.selected) {
      double textMoveX = _tmpMoveX + focalMoveX;
      double textMoveY = _tmpMoveY + focalMoveY;
      _tempText.offset = Offset(textMoveX, textMoveY);
      _tempText.scale = scale;
    } else {
      /// 这里是旋转使用，暂时去掉
      // double absMoveX;
      // double absMoveY;
      // // 90度
      // if (absRotate == (pi / 2)) {
      //   absMoveX = _tmpMoveY - focalMoveY / _tmpScale;
      //   absMoveY = _tmpMoveX + focalMoveX / _tmpScale;
      // } else if (absRotate == pi) {
      //   // 180度
      //   absMoveX = _tmpMoveX - focalMoveX / _tmpScale;
      //   absMoveY = _tmpMoveY - focalMoveY / _tmpScale;
      // } else if (absRotate == (pi * 1.5)) {
      //   // 270 度
      //   absMoveX = _tmpMoveY + focalMoveY / _tmpScale;
      //   absMoveY = _tmpMoveX - focalMoveX / _tmpScale;
      // } else {
      //   // 0度
      //   absMoveX = _tmpMoveX + focalMoveX / _tmpScale;
      //   absMoveY = _tmpMoveY + focalMoveY / _tmpScale;
      // }
      _moveX = _tmpMoveX + focalMoveX / _tmpScale;
      _moveY = _tmpMoveY + focalMoveY / _tmpScale;
      _scale = scale;
    }

    setState(() {});
  }

  /// 处理滑动开始事件
  void _handleOnPanStart(Offset point) {
    _tempLine = DrawLine()
      ..color = _brushColor
      ..lineWidth = _brushWidth;
    _tempLine.linePath.add(point);
    drawBoradListenable.add(_tempLine);
  }

  /// 处理滑动更新事件
  void _handleOnPanUpdate(Offset point) {
    if (_tempLine == null) {
      _handleOnPanStart(point);
    } else {
      _tempLine.linePath.add(point);
      drawBoradListenable.setLast(_tempLine);
      setState(() {});
    }

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

  /// 设置画笔颜色
  void setBrushColor(Color color) {
    _brushColor = color;
  }

  /// 设置画笔宽度
  void setBrushWidth(double width) {
    _brushWidth = width;
  }

  /// 添加线
  void addLine(DrawLine line) {
    drawBoradListenable.add(line);
    setState(() {});
  }

  /// 更新文字信息
  void updateTempText(DrawText text) {
    _tempText = text;
    setState(() {});
  }

  /// 添加文字
  void addText(DrawText text) {
    if (text?.text?.isEmpty ?? true) {
      throw Exception('添加的文字不能为空');
    }
    drawBoradListenable.add(text);
    if (text.selected) {
      if (_tempText != null) {
        _tempText.selected = false;
      }
      _tempText = drawBoradListenable.drawList.last;
      _boradMode = BoradMode.Edit;
    }
    setState(() {});
  }

  /// 设置旋转角度
  /// [rotation] 旋转角度
  void setBackgroundRotation(double rotation) {
    _bgRotation = rotation;
    setState(() {});
  }

  /// 设置缩放
  /// [scale] 缩放
  void setScale(double scale) {
    _bgScale = scale;
    setState(() {});
  }

  /// 设置移动位置
  /// [moveX] 移动的 X
  /// [moveY] 移动的 Y
  void setMove(double moveX, double moveY) {
    _moveX = moveX;
    _moveY = moveY;
    setState(() {});
  }

  /// 回退
  void undo() {
    var last = drawBoradListenable.removeLast();
    if (last == _tempText) {
      _tempText = null;
    }
    // 设置编辑模式
    _boradMode = BoradMode.Draw;
    // setState(() {});
  }

  /// 清空
  void clearDraw() {
    drawBoradListenable.clear();
    _tempText = null;
    _boradMode = BoradMode.Draw;
    // setState(() {});
  }

  /// 重置
  void resetParams() {
    _scale = 1.0;
    _moveX = 0;
    _moveY = 0;
    if (_tempText != null) {
      _tempText.selected = false;
    }
    _boradMode = BoradMode.Draw;
    setState(() {});
  }

  /// 设置图片矩阵
  void setImageRect(Rect rect) {
    this.imgRect = rect;
    setState(() {});
  }

  // 获取为图片
  Future<Uint8List> getImage({double pixelRatio = 1}) async {
    /// 恢复到默认状态
    resetParams();
    await Future.delayed(Duration(milliseconds: 300));

    /// 开始保存图片
    RenderRepaintBoundary boundary =
        _drawToImageKey.currentContext.findRenderObject();
    ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData.buffer.asUint8List();
    return pngBytes;
  }
}
