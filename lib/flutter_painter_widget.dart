import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

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
    this.scale,
    this.moveX,
    this.moveY,
    this.onTapText,
    this.onPointerCount,
    this.enableLineEdit = true,
    this.mouseScrollZoom = false,
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
  // 缩放
  final double? scale;
  // 移动x
  final double? moveX;
  // 移动x
  final double? moveY;
  // 启用线的编辑
  final bool enableLineEdit;
  // 鼠标滚动为缩放或移动
  final bool mouseScrollZoom;
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
  Rect? _tmpRect = Rect.zero;
  double _bgRotation = 0.0;
  // 获取旋转角度
  double get backgroundRotation => _bgRotation;
  Offset _tmpFocal = Offset.zero;

  /// 是否被 90度的奇数，就是90和270
  bool get is90 => (_bgRotation ~/ (pi / 2)).isOdd;

  /// 矩阵信息
  late Matrix4 _matrix4;

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
  // 编辑内容当前状态为移动
  bool tempEditMove = true;
  // 点击添加绘制内容
  var _clickAddDraw;
  dynamic get clickAddDraw => _clickAddDraw;
  // 获取点击贴图的缩放大小
  double get clickAddDrawScale => _clickAddDraw?.scale ?? 1.0;
  // 临时按下事件记录，防止事件错乱
  TapUpDetails? _tempTapUpDetails;
  // 画板页面大小
  Size? _boradSize;
  Size get boradSize =>
      _boradSize ??
      _drawBoradKey.currentContext?.size ??
      MediaQuery.of(context).size;
  // 画布页面大小
  Size? _painterSize;
  // 鼠标效果
  MouseCursor cursor = MouseCursor.defer;
  @override
  void initState() {
    /// 设置默认
    if (widget.brushColor != null) {
      _brushColor = widget.brushColor!;
    }
    if (widget.brushWidth != null) {
      _brushWidth = widget.brushWidth!;
    }
    // 获取缩放
    if (widget.scale != null) {
      _scale = widget.scale!;
    }
    // 获取移动
    if (widget.moveX != null) {
      _moveX = widget.moveX!;
    }
    if (widget.moveY != null) {
      _moveY = widget.moveY!;
    }
    // 禁用默认的右键事件处理
    disableRightClick();
    super.initState();
  }

  @override
  void dispose() {
    //启用右键事件处理
    enableRightClick();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // 获取画布大小
    double newWidth = widget.width ?? double.infinity;
    double newHeight = widget.height ?? double.infinity;
    if (widget.width != null && widget.height != null) {
      newWidth = is90 ? widget.height! : widget.width!;
      newWidth = newWidth * bgScale;
      newHeight = is90 ? widget.width! : widget.height!;
      newHeight = newHeight * bgScale;
    }
    _painterSize = Size(newWidth, newHeight);
    // 计算矩阵
    _matrix4 = Matrix4.identity()
      ..scale(_scale, _scale)
      ..translate(_moveX, _moveY);
    return Scaffold(
      key: _drawBoradKey,
      body: Listener(
        onPointerDown: (event) {
          _onPointerDown(event.buttons);
        },
        onPointerUp: (event) {
          _onPointerUp(event.buttons);
          // 这里是解决点击后再绘制会从点击的那个点开始绘制的问题，最终效果是多出一段距离来
          _tempLine = null;
        },
        onPointerCancel: (event) {
          // 这个回调彻底解决手指数异常的问题
          _onPointerUp(event.buttons);
        },
        onPointerHover: (event) {
          _onPointerHover(event);
        },
        onPointerMove: (event) {
          if (boradMode == BoradMode.Draw) {
            _handleOnPanUpdate(event.localPosition);
          }
        },
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            _onPointerScroll(event);
          }
        },
        child: MouseRegion(
          cursor: cursor,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {},
            onTapUp: (details) {
              // 设置按下事件信息
              _tempTapUpDetails = details;
            },
            onTap: () {
              _handleOnTap();
              // 清空按下信息，方式错误绘制
              _tempTapUpDetails = null;
            },
            onScaleStart: (details) {
              if (boradMode == BoradMode.Zoom || boradMode == BoradMode.Edit) {
                _handleOnScaleStart(details);
              }
            },
            onScaleUpdate: (details) {
              if (boradMode == BoradMode.Zoom || boradMode == BoradMode.Edit) {
                _handleOnScaleUpdate(details);
              }
            },
            onScaleEnd: (details) {
              _tempLine = null;
              _tempTapUpDetails = null;
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
                        RotatedBox(
                          quarterTurns: _bgRotation ~/ (pi / 2),
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

  /// 鼠标悬停事件
  void _onPointerHover(PointerHoverEvent event) {
    if (boradMode == BoradMode.Edit) {
      Offset lp = event.localPosition;
      _handleEditMouseCursor(lp);
    }
  }

  /// 处理缩放和移动的切换以及鼠标状态
  void _handleEditMouseCursor(Offset offset) {
    Offset newOffset = getNewPoint(offset);
    cursor = MouseCursor.defer;
    if (_tempEdit != null && _tempEdit is DrawEdit && _tempEdit.selected) {
      if (_tempEdit.rect.contains(newOffset)) {
        cursor = SystemMouseCursors.move;
        tempEditMove = true;
      }
      // 计算拉伸区域
      double delRadius = _tempEdit.delRadius;
      Rect tempRect = _tempEdit.rect;
      Rect delRect = Rect.fromCircle(
        center: tempRect.bottomRight,
        radius: delRadius,
      );
      // 编辑选中并且命中删除区域
      if (delRect.contains(newOffset)) {
        cursor = SystemMouseCursors.resizeDownRight;
        tempEditMove = false;
      }
    }
    setState(() {});
  }

  /// 鼠标滚轮事件
  void _onPointerScroll(PointerScrollEvent event) {
    Offset center = MediaQuery.of(context).size.center(Offset.zero);
    double scaleRatio = -event.scrollDelta.dy / center.dy;
    // 有选中文字处理选中文字
    if (_tempEdit != null && _tempEdit.selected) {
      _tempEdit.scale = getNewScale(_tempEdit.scale + scaleRatio);
      drawBoradListenable.update();
    } else {
      if (widget.mouseScrollZoom) {
        // 缩放
        double newScale = scale + scaleRatio;
        setScale(newScale);
      } else {
        // 移动
        _moveY -= event.scrollDelta.dy;
        setState(() {});
      }
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
    Offset lp = _tempTapUpDetails!.localPosition;
    lp = getNewPoint(lp);
    if (_tempEdit != null && _tempEdit is DrawEdit) {
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
    var editList = drawBoradListenable.drawList.whereType<DrawEdit>().where(
        (drawItem) => !((drawItem is DrawLine) &&
            !drawItem.enable &&
            drawItem.rect != null));
    // 是否为取消选中
    bool cancelEdit = false;
    // 遍历查看是否命中事件
    for (var item in editList) {
      Rect? editRect = item.rect;
      if (editRect == null) {
        continue;
      }
      //计算是否命中事件
      if (editRect.contains(lp)) {
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
        // 选中状态变为不选中则认定为取消选中状态
        if (item.selected) {
          cancelEdit = true;
        }
        // 未命中，不选中
        drawBoradListenable.setSelect(item, false);
        _boradMode = BoradMode.Draw;
        _pointerCount = 0;
      }
    }
    // 如果有点击添加的内容，则添加到画板中
    if (_clickAddDraw != null && boradMode == BoradMode.Draw && !cancelEdit) {
      var newClickDraw = _clickAddDraw.copy();
      Size drawSize = newClickDraw.drawSize;
      newClickDraw.offset = lp.translate(
          -drawSize.width * clickAddDrawScale / 2,
          -drawSize.height * clickAddDrawScale / 2);
      drawBoradListenable.add(newClickDraw);
      return;
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
      _tmpRect = _tempEdit.rect;
      _handleEditMouseCursor(_tmpFocal);
    } else {
      _tmpMoveX = _moveX;
      _tmpMoveY = _moveY;
      _tmpScale = _scale;
    }
  }

  /// 处理缩放移动更新事件
  void _handleOnScaleUpdate(ScaleUpdateDetails details) {
    // 计算运动距离
    double focalMoveX = (details.focalPoint.dx - _tmpFocal.dx);
    double focalMoveY = (details.focalPoint.dy - _tmpFocal.dy);
    double newScale = _tmpScale! * details.scale;
    // 有选中文字处理选中文字
    if (_tempEdit != null && _tempEdit.selected) {
      double editMoveX = _tmpMoveX! + focalMoveX / _scale;
      double editMoveY = _tmpMoveY! + focalMoveY / _scale;
      if (tempEditMove) {
        _tempEdit.offset = Offset(editMoveX, editMoveY);
      } else {
        // 当前的移动距离/页面缩放/原始宽度+原始缩放=新缩放
        newScale =
            focalMoveX / _scale / (_tmpRect!.width / _tmpScale!) + _tmpScale!;
        _tempEdit.scale = getNewScale(newScale);
        // 如果点击绘制有内容，则跟着缩放一下
        if (clickAddDraw != null &&
            clickAddDraw.runtimeType == _tempEdit.runtimeType) {
          clickAddDraw.scale = getNewScale(newScale);
        }
      }
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
    Offset newPoint = getNewPoint(point);
    if (_tempLine == null) {
      _handleOnPanStart(newPoint);
    } else {
      // 如果最后一个是相同的点就不添加了
      if (_tempLine!.linePath.last == newPoint) {
        return;
      }
      _tempLine!.linePath.add(newPoint);
      drawBoradListenable.setLast(_tempLine!);
    }
  }

  /// 获取新的坐标点
  Offset getNewPoint(Offset point) {
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
    if (image.clickAdd) {
      setClickAddDraw(image);
      return;
    }
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
      bool selected = true,
      bool clickAdd = false}) async {
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
        ..scale = scale
        ..clickAdd = clickAdd,
    );
  }

  /// 设置点击添加内容
  /// [draw] 绘制组件
  void setClickAddDraw(dynamic draw) {
    _clickAddDraw = draw;
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
    if (newScale > 5.0) {
      newScale = 5.0;
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

  /// 获取为图片
  /// [pixelRatio]分辨率
  /// [delayed] 等待时长
  Future<Uint8List> getImage({double pixelRatio = 1, int delayed = 100}) async {
    // 恢复到默认状态
    resetParams();
    // 这里是为了防止图片生成不了
    await Future.delayed(Duration(milliseconds: delayed));

    // 开始保存图片
    RenderRepaintBoundary boundary = _drawToImageKey.currentContext!
        .findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    ByteData byteData = await (image.toByteData(format: ui.ImageByteFormat.png)
        as Future<ByteData>);
    Uint8List pngBytes = byteData.buffer.asUint8List();
    return pngBytes;
  }
}
