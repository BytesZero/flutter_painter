import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_painter/draw/draw_edit.dart';
import 'package:flutter_painter/draw/draw_image.dart';

import 'draw/base_line.dart';
import 'draw/draw_borad.dart';
import 'draw/draw_eraser.dart';
import 'draw/draw_line.dart';
import 'draw/draw_text.dart';
import 'platform/painter_platform.dart';

/// Flutter Painter
class FlutterPainterWidget extends StatefulWidget {
  FlutterPainterWidget({
    Key? key,
    required this.background,
    this.width,
    this.height,
    this.brushColor,
    this.brushWidth,
    this.onTapText,
    this.onPointerCount,
    this.enableLineEdit = true,
  }) : super(key: key);
  // 背景 Widget
  final Widget background;
  // 宽度
  final double? width;
  // 高度
  final double? height;
  // 画笔颜色
  final Color? brushColor;
  // 画笔粗细
  final double? brushWidth;
  // 启用线的编辑
  final bool enableLineEdit;
  // 文字编辑点击
  final ValueChanged<DrawText>? onTapText;
  // 手指按下数量变化监听
  final ValueChanged<int>? onPointerCount;

  @override
  FlutterPainterWidgetState createState() => FlutterPainterWidgetState();
}

class FlutterPainterWidgetState extends State<FlutterPainterWidget>
    with AutomaticKeepAliveClientMixin {
  // 绘制转成图片的 key
  GlobalKey _drawToImageKey = GlobalKey();
  // 画板的 key
  GlobalKey _drawBoradKey = GlobalKey();

  /// 默认缩放信息
  double _scale = 1.0;
  double get scale => _scale;
  double _bgScale = 1.0;
  double get bgScale => _bgScale;
  double? _tmpScale = 1.0;
  double _moveX = 0.0;
  double get moveX => _moveX;
  double? _tmpMoveX = 0.0;
  double _moveY = 0.0;
  double get moveY => _moveY;
  double? _tmpMoveY = 0.0;
  double _bgRotation = 0.0;
  // 获取旋转角度
  double get backgroundRotation => _bgRotation;
  Offset _tmpFocal = Offset.zero;

  /// 是否被 90度的奇数，就是90和270
  bool get is90 => (_bgRotation ~/ (pi / 2)).isOdd;

  /// 矩阵信息
  late Matrix4 _matrix4;
  late Matrix4 _bgMatrix4;

  /// 图片矩阵
  Rect? imgRect;

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
  // 是否是清除模式
  bool _isEraseMode = false;
  // 擦除画笔粗细
  double _eraseWidth = 8;

  // 绘制集合
  DrawBoradListenable drawBoradListenable = DrawBoradListenable();
  // 临时线
  BaseLine? _tempLine;
  // 临时编辑内容，标记选中赋值
  var _tempEdit;
  // 临时按下事件记录，防止事件错乱
  TapDownDetails? _tempTapDownDetails;
  // 画板页面大小
  Size? _boradSize;
  Size get boradSize =>
      _boradSize ??
      _drawBoradKey.currentContext?.size ??
      MediaQuery.of(context).size;
  // 画布页面大小
  Size? _painterSize;
  @override
  void initState() {
    /// 设置默认
    if (widget.brushColor != null) {
      _brushColor = widget.brushColor!;
    }
    if (widget.brushWidth != null) {
      _brushWidth = widget.brushWidth!;
    }
    // 禁用默认的右键事件处理
    disableRightClick();
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
    _bgMatrix4 = Matrix4.identity()..scale(_bgScale, _bgScale);
    // ..rotateZ(_bgRotation);
    double newWidth = widget.width ?? double.infinity;
    double newHeight = widget.height ?? double.infinity;
    if (widget.width != null && widget.height != null) {
      newWidth = is90 ? widget.height! : widget.width!;
      newWidth = newWidth * bgScale;
      newHeight = is90 ? widget.width! : widget.height!;
      newHeight = newHeight * bgScale;
      _painterSize = Size(newWidth, newHeight);
    }
    print(
        'FlutterPainter size ${MediaQuery.of(context).size} newWidth $newWidth newHeight $newHeight');
    return Scaffold(
      key: _drawBoradKey,
      body: Listener(
        onPointerDown: (event) {
          _onPointerDown(event.buttons);
        },
        onPointerUp: (event) {
          _onPointerUp(event.buttons);
        },
        onPointerCancel: (event) {
          // 这个回调彻底解决手指数异常的问题
          _onPointerUp(event.buttons);
        },
        onPointerHover: (event) {},
        onPointerMove: (event) {},
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            _onPointerScroll(event);
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            // 设置按下事件信息
            _tempTapDownDetails = details;
            // 如果橡皮擦，则按下就开始擦除
            if (_isEraseMode) {
              _handleOnPanUpdate(details.localPosition);
              _handleOnPanUpdate(
                  details.localPosition.translate(_eraseWidth, 0));
            }
          },
          onTapUp: (details) {
            /// 这里是解决点击后再绘制会从点击的那个点开始绘制的问题，最终效果是多出一段距离来
            _tempLine = null;
          },
          onTap: () {
            _handleOnTap();
            // 清空按下信息，方式错误绘制
            _tempTapDownDetails = null;
          },
          onScaleStart: (details) {
            print('FlutterPainter onScaleStart ${details.toString()}');
            if (boradMode == BoradMode.Zoom || boradMode == BoradMode.Edit) {
              _handleOnScaleStart(details);
            } else {
              // 处理按下事件到滑动事件的过渡阶段的距离
              if (_tempTapDownDetails != null) {
                _handleOnPanUpdate(_tempTapDownDetails!.localPosition);
              }
              _handleOnPanUpdate(details.localFocalPoint);
            }
          },
          onScaleUpdate: (details) {
            if (boradMode == BoradMode.Zoom || boradMode == BoradMode.Edit) {
              _handleOnScaleUpdate(details);
            } else {
              _handleOnPanUpdate(details.localFocalPoint);
            }
          },
          onScaleEnd: (details) {
            _tempLine = null;
            _tempTapDownDetails = null;
          },
          child: Center(
            child: SizedBox(
              width: newWidth,
              height: newHeight,
              child: RepaintBoundary(
                key: _drawToImageKey,
                child: Transform(
                  transform: _matrix4,
                  alignment: FractionalOffset.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform(
                        transform: _bgMatrix4,
                        alignment: FractionalOffset.center,
                        child: RotatedBox(
                          quarterTurns: _bgRotation ~/ (pi / 2),
                          child: widget.background,
                        ),
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
      ),
    );
  }

  /// 设置画板模式
  Future<void> setBoradMode(BoradMode mode) async {
    _boradMode = mode;
    // 不是编辑模式设置空
    if (mode != BoradMode.Edit && _tempEdit != null) {
      drawBoradListenable.setSelect(_tempEdit, false);
      _tempEdit = null;
    }
    setState(() {});
  }

  /// 抬起事件
  void _onPointerDown(int buttons) {
    if (_pointerCount < 0) _pointerCount = 0;
    _pointerCount += 1;
    _switchBoradMode(buttons);
  }

  /// 抬起、取消事件
  void _onPointerUp(int buttons) {
    if (_pointerCount > 0) _pointerCount -= 1;
    if (_pointerCount < 1) {
      _switchBoradMode(buttons);
    }
  }

  /// 鼠标滚轮事件
  void _onPointerScroll(PointerScrollEvent event) {
    Offset center = MediaQuery.of(context).size.center(Offset.zero);
    double scaleRatio = -event.scrollDelta.dy / center.dy;

    /// 有选中文字处理选中文字
    if (_tempEdit != null && _tempEdit.selected) {
      _tempEdit.scale = getNewScale(_tempEdit.scale + scaleRatio);
      drawBoradListenable.update();
    } else {
      double newScale = scale + scaleRatio;
      double newMoveX = (center.dx - event.position.dx) / newScale;
      double newMoveY = (center.dy - event.position.dy) / newScale;
      // if (newScale > 1.0) {
      //   _moveX = newMoveX * (newScale - 0.8);
      //   _moveY = newMoveY * (newScale - 0.8);
      // } else {
      //   _moveX = newMoveX * (newScale - 0.5).clamp(0.0, 0.5);
      //   _moveY = newMoveY * (newScale - 0.5).clamp(0.0, 0.5);
      // }
      setScale(newScale);
    }
  }

  /// 切换画板模式
  void _switchBoradMode(int buttons) {
    if (_boradMode != BoradMode.Edit) {
      if (_pointerCount > 1 || buttons == kSecondaryMouseButton) {
        _boradMode = BoradMode.Zoom;
      } else {
        _boradMode = BoradMode.Draw;
      }
    }
    // 返回按下手指数
    if (widget.onPointerCount != null) {
      widget.onPointerCount!(_pointerCount);
    }
  }

  /// 处理点击事件
  void _handleOnTap() {
    Offset lp = _tempTapDownDetails!.localPosition;
    lp = _getNewPoint(lp);
    if (_tempEdit != null) {
      // 计算删除区域
      double delRadius = _tempEdit.delRadius;
      Rect tempRect = _tempEdit.rect;
      Rect delRect = Rect.fromCircle(
        center: tempRect.topLeft,
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
    // 仅获取可编辑内容
    var editList = drawBoradListenable.drawList
        .whereType<DrawEdit>()
        .where((drawItem) => !((drawItem is DrawLine) && !drawItem.enable));
    // 遍历查看是否命中事件
    for (var item in editList) {
      Rect textRect = item.rect;
      //计算是否命中事件
      if (textRect.contains(lp)) {
        // 命中的是上次命中的，那么触发编辑
        if (item.selected) {
          // 二次命中触发文字编辑
          if ((item is DrawText) && (widget.onTapText != null)) {
            widget.onTapText!(item);
          }
        } else {
          // 先设置为不选中状态
          drawBoradListenable.setSelect(_tempEdit, false);
          // 然后赋值设置为选中状态
          _tempEdit = item;
          drawBoradListenable.setSelect(_tempEdit, true);
        }
        // 设置为编辑状态
        _boradMode = BoradMode.Edit;
        break;
      } else {
        // 未命中，不选中
        drawBoradListenable.setSelect(item, false);
        _boradMode = BoradMode.Draw;
        _pointerCount = 0;
      }
    }
  }

  /// 处理缩放移动开始事件
  void _handleOnScaleStart(ScaleStartDetails details) {
    _tmpFocal = details.focalPoint;
    // 有选中文字处理选中文字
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
    double newScale = _tmpScale! * details.scale;

    /// 有选中文字处理选中文字
    if (_tempEdit != null && _tempEdit.selected) {
      double textMoveX = _tmpMoveX! + focalMoveX / _scale;
      double textMoveY = _tmpMoveY! + focalMoveY / _scale;
      _tempEdit.offset = Offset(textMoveX, textMoveY);
      _tempEdit.scale = getNewScale(newScale);
      drawBoradListenable.update();
    } else {
      _moveX = _tmpMoveX! + focalMoveX / _tmpScale!;
      _moveY = _tmpMoveY! + focalMoveY / _tmpScale!;
      setScale(newScale);
    }
  }

  /// 处理滑动开始事件
  void _handleOnPanStart(Offset point) {
    // 擦除模式（橡皮擦）
    if (_isEraseMode) {
      _tempLine = DrawEraser()..lineWidth = _eraseWidth;
    } else {
      _tempLine = DrawLine()
        ..color = _brushColor
        ..lineWidth = _brushWidth
        ..enable = widget.enableLineEdit;
    }
    _tempLine!.linePath.add(point);
    drawBoradListenable.add(_tempLine!);
  }

  /// 处理滑动更新事件
  void _handleOnPanUpdate(Offset point) {
    Offset newPoint = _getNewPoint(point);
    if (_tempLine == null) {
      _handleOnPanStart(newPoint);
    } else {
      _tempLine!.linePath.add(newPoint);
      drawBoradListenable.setLast(_tempLine!);
    }
  }

  /// 获取新的坐标点
  Offset _getNewPoint(Offset point) {
    _boradSize =
        _drawBoradKey.currentContext?.size ?? MediaQuery.of(context).size;
    _painterSize = _drawToImageKey.currentContext?.size ?? Size.zero;
    // 构建画布矩形（背景图片）
    Rect rect = Rect.fromLTWH(0, 0, _painterSize!.width, _painterSize!.height);
    // 执行矩阵变换
    Rect newRect = MatrixUtils.transformRect(_matrix4, rect);
    // 计算画布距离画板（手势接收区域）的距离
    Offset diffOffset = newRect.center - boradSize.center(Offset.zero);
    // 计算手势偏移量，并恢复到矩阵变换前的大小
    Offset newPoint = (point + diffOffset) / scale;
    // 添加移动产生的偏移量
    newPoint = newPoint - Offset(moveX, moveY) * 2;
    print(
        'FlutterPainter _handleOnPanUpdate: _boradSize:$_boradSize rect: $rect ,newRect:$newRect,diffOffset:$diffOffset , point: $point, newPoint: $newPoint');
    print(
        'FlutterPainter _handleOnPanUpdate: $point -> $newPoint moveX: $_moveX moveY: $_moveY scale: $_scale');
    return newPoint;
  }

  /// 设置画笔颜色
  void setBrushColor(Color color) {
    _brushColor = color;
    setEraseMode(false);
  }

  /// 设置画笔宽度
  void setBrushWidth(double width) {
    _brushWidth = width;
    setEraseMode(false);
  }

  /// 添加线
  void addLine(DrawLine line) {
    drawBoradListenable.add(line);
  }

  /// 添加文字
  void addText(DrawText text) {
    if (text.text?.isEmpty ?? true) {
      throw Exception('添加的文字不能为空');
    }
    drawBoradListenable.add(text);
    if (text.selected) {
      // 去掉原有的选中状态
      drawBoradListenable.setSelect(_tempEdit, false);
      _tempEdit = text;
      _boradMode = BoradMode.Edit;
    }
  }

  /// 更新文字信息
  void updateText(DrawText text) {
    _tempEdit = text;
    drawBoradListenable.update();
  }

  /// 添加图片
  /// [image] 绘制图片
  void addImage(DrawImage image) {
    drawBoradListenable.add(image);
    if (image.selected) {
      // 去掉原有的选中状态
      drawBoradListenable.setSelect(_tempEdit, false);
      _tempEdit = image;
      _boradMode = BoradMode.Edit;
    }
  }

  /// 添加图片
  /// [imgPath] 图片地址
  /// [offset] 图片位置偏移量
  /// [drawSize] 绘制图片大小
  void addImageAsset(
      {required String imgPath,
      required Offset offset,
      Size? drawSize,
      double scale = 1.0,
      bool selected = true}) async {
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
        ..selected = selected
        ..drawSize = drawSize
        ..scale = scale,
    );
  }

  /// 设置旋转角度
  /// [rotation] 旋转角度
  void setBackgroundRotation(double rotation) {
    _bgRotation = rotation;
    setState(() {});
  }

  /// 设置背景缩放
  /// [newBgScale] 缩放
  void setBgScale(double newBgScale) {
    _bgScale = newBgScale;
    setState(() {});
  }

  /// 获取新的缩放大小
  /// [newScale] 缩放大小
  double getNewScale(double newScale) {
    if (newScale > 3.0) {
      newScale = 3.0;
    } else if (newScale < 0.5) {
      newScale = 0.5;
    }
    return newScale;
  }

  /// 设置缩放
  /// [newScale] 缩放
  void setScale(double newScale) {
    _scale = getNewScale(newScale);
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

  /// 设置擦除模式
  /// [isEraseMode] 是否为擦除模式
  void setEraseMode(bool isEraseMode) {
    _isEraseMode = isEraseMode;
  }

  /// 设置擦除宽度
  void setEraseWidth(double width) {
    _eraseWidth = width;
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
    drawBoradListenable.setSelect(_tempEdit, false);
    _tempEdit = null;
    _boradMode = BoradMode.Draw;
    _isEraseMode = false;
    _eraseWidth = 8;
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
    RenderRepaintBoundary boundary = _drawToImageKey.currentContext!
        .findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    ByteData byteData = await (image.toByteData(format: ui.ImageByteFormat.png)
        as Future<ByteData>);
    Uint8List pngBytes = byteData.buffer.asUint8List();
    return pngBytes;
  }
}

/// 自定剪裁
class PainterClipRect extends CustomClipper<Rect> {
  final Rect rect;
  PainterClipRect(this.rect);
  @override
  Rect getClip(Size size) {
    print('PainterClipRect getClip ${rect.toString()} size:$size');
    return rect;
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return true;
  }
}
