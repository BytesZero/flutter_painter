import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_painter/draw/draw_edit.dart';
import 'package:flutter_painter/draw/draw_image.dart';
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
  // 临时编辑内容，标记选中赋值
  var _tempEdit;
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
            child: Listener(
              onPointerDown: (event) {
                // 处理触点异常的问题
                if (_pointerCount < 0) _pointerCount = 0;
                _pointerCount++;
                _switchBoradMode();
              },
              onPointerUp: (event) {
                // 处理触点异常的问题
                if (_pointerCount > 0) _pointerCount--;
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
                  // 处理触点异常导致的无法绘制的问题
                  if (_pointerCount > 1) _pointerCount = 1;
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
                      ),
                    ),
                  ],
                ),
              ),
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
    if (mode != BoradMode.Edit && _tempEdit != null) {
      _tempEdit.selected = false;
      _tempEdit = null;
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
    }

    /// 返回按下手指数
    if (widget.onPointerCount != null) {
      widget.onPointerCount(_pointerCount);
    }
  }

  /// 处理点击事件
  void _handleOnTap() {
    Offset lp = _tempTapDownDetails.localPosition;
    if (_tempEdit != null) {
      /// 计算删除区域
      double delRadius = _tempEdit.delRadius;
      Rect tempTextRect = _tempEdit.rect;
      Rect delRect = Rect.fromCircle(
        center: tempTextRect.topLeft,
        radius: delRadius,
      );
      // 编辑选中并且命中删除区域
      if (_tempEdit.selected && delRect.contains(lp)) {
        drawBoradListenable.remove(_tempEdit);
        _tempEdit = null;
        _boradMode = BoradMode.Draw;
        return;
      }
    }

    /// 只获取文字
    var editList = drawBoradListenable.drawList.whereType<DrawEdit>();
    // 遍历查看是否命中事件
    for (var item in editList) {
      Rect textRect = item.rect;
      //计算是否命中事件
      if (textRect.contains(lp)) {
        // 命中的是上次命中的，那么触发编辑
        if (item.selected) {
          // 二次命中触发文字编辑
          if ((item is DrawText) && (widget.onTapText != null)) {
            widget.onTapText(item);
          }
        } else {
          // 先设置为不选中状态
          _tempEdit?.selected = false;
          // 然后赋值设置为选中状态
          _tempEdit = item;
          _tempEdit.selected = true;
          _boradMode = BoradMode.Edit;
          setState(() {});
        }
        break;
      } else {
        // 未命中，不选中
        item.selected = false;
        _tempEdit = null;
        _boradMode = BoradMode.Draw;
        setState(() {});
      }
    }
  }

  /// 处理缩放移动开始事件
  void _handleOnScaleStart(ScaleStartDetails details) {
    _tmpFocal = details.focalPoint;

    /// 有选中文字处理选中文字
    if (_tempEdit != null && _tempEdit.selected) {
      _tmpMoveX = _tempEdit.offset.dx;
      _tmpMoveY = _tempEdit.offset.dy;
      _tmpScale = _tempEdit.scale;
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
    if (_tempEdit != null && _tempEdit.selected) {
      double textMoveX = _tmpMoveX + focalMoveX;
      double textMoveY = _tmpMoveY + focalMoveY;
      _tempEdit.offset = Offset(textMoveX, textMoveY);
      _tempEdit.scale = scale;
    } else {
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
    }
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
  }

  /// 更新文字信息
  void updateTempText(DrawText text) {
    _tempEdit = text;
  }

  /// 添加文字
  void addText(DrawText text) {
    if (text?.text?.isEmpty ?? true) {
      throw Exception('添加的文字不能为空');
    }
    drawBoradListenable.add(text);
    if (text.selected) {
      // 去掉原有的选中状态
      if (_tempEdit != null) {
        _tempEdit.selected = false;
      }
      _tempEdit = text;
      _boradMode = BoradMode.Edit;
    }
  }

  /// 添加图片
  /// [image] 绘制图片
  void addImage(DrawImage image) {
    drawBoradListenable.add(image);
  }

  /// 添加图片
  /// [imgPath] 图片地址
  /// [offset] 图片位置偏移量
  /// [drawSize] 绘制图片大小
  void addImageAsset({String imgPath, Offset offset, Size drawSize}) async {
    // 获取图片数据
    ByteData data = await rootBundle.load(imgPath);
    Uint8List bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    ui.Image imgData = await decodeImageFromList(bytes);

    // 添加绘制图片
    addImage(
      DrawImage()
        ..image = imgData
        ..offset = offset
        // ..selected = true
        ..drawSize = drawSize,
    );
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
    if (last == _tempEdit) {
      _tempEdit = null;
    }
    // 设置编辑模式
    _boradMode = BoradMode.Draw;
    _pointerCount = 0;
  }

  /// 清空
  void clearDraw() {
    drawBoradListenable.clear();
    _tempEdit = null;
    _boradMode = BoradMode.Draw;
    _pointerCount = 0;
  }

  /// 重置
  void resetParams() {
    _scale = 1.0;
    _moveX = 0;
    _moveY = 0;
    if (_tempEdit != null) {
      _tempEdit.selected = false;
    }
    _boradMode = BoradMode.Draw;
    _pointerCount = 0;
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
