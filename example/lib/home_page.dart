import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'draw/draw_borad.dart';
import 'draw/draw_line.dart';
import 'draw/base_draw.dart';
import 'draw/draw_text.dart';
import 'edit_text_page.dart';

/// 首页
class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  String imageUrl = 'assets/images/huaxiong.jpeg';
  // 绘制转成图片的 key
  GlobalKey drawToImageKey = GlobalKey();

  /// 绘制手势 key
  var drawGestureKey = GlobalKey();

  /// 默认缩放信息
  double _scale = 1.0;
  double _tmpScale = 1.0;
  double _moveX = 0.0;
  double _tmpMoveX = 0.0;
  double _moveY = 0.0;
  double _tmpMoveY = 0.0;
  double _rotation = 0.0;
  double _tmpRotation = 0.0;

  Offset _tmpFocal = Offset.zero;
  Matrix4 matrix4;

  // 画板模式
  BoradMode boradMode = BoradMode.Zoom;
  //选择颜色
  Color selectColor = Colors.red;
  // 颜色列表
  List<Color> colorList = [
    Colors.red,
    Colors.white,
    Colors.black,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.orange,
  ];
  //选择颜色
  double brushWidth = 4;
  // 笔刷粗细列表
  List<double> brushWidthList = [
    1,
    2,
    4,
    6,
    8,
  ];
  // 绘制集合
  List<BaseDraw> paintList = [];
  // 临时线
  DrawLine _tempLine;
  // 临时文字，标记选中赋值
  DrawText _tempText;
  // 临时按下事件记录，防止时间错乱
  TapDownDetails _tempTapDownDetails;

  @override
  bool get wantKeepAlive => true;

  Offset textOffset = Offset(100, 40);

  @override
  Widget build(BuildContext context) {
    matrix4 = Matrix4.identity()
      ..scale(_scale, _scale)
      ..translate(_moveX, _moveY);
    // ..rotateZ(_rotation);
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Painter Demo'),
      ),
      body: Container(
        color: Colors.white,
        child: RepaintBoundary(
          key: drawToImageKey,
          child: Center(
            child: Transform(
              transform: matrix4,
              alignment: FractionalOffset.center,
              child: Stack(
                children: [
                  Center(child: Image.asset(imageUrl)),
                  CustomPaint(
                    size: Size.infinite,
                    painter: DrawBorad(paintList: paintList),
                    child: boradMode == BoradMode.Zoom
                        ? GestureDetector(
                            onTapDown: (details) {
                              // 设置按下事件信息
                              _tempTapDownDetails = details;
                            },
                            onTap: () {
                              debugPrint('onTap');
                              handleOnTap();
                            },
                            onScaleStart: (details) {
                              handleOnScaleStart(details);
                            },
                            onScaleUpdate: (details) {
                              handleOnScaleUpdate(details);
                            },
                          )
                        : GestureDetector(
                            key: drawGestureKey,
                            onPanStart: (details) {
                              handleOnPanStart();
                            },
                            onPanUpdate: (details) {
                              handleOnPanUpdate(details);
                            },
                            onPanEnd: (details) {
                              _tempLine = null;
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: colorList.map((color) {
                return GestureDetector(
                  onTap: () {
                    selectColor = color;
                    if (_tempText != null && _tempText.selected) {
                      _tempText.color = selectColor;
                    }
                    setState(() {});
                  },
                  child: Container(
                    height: 24,
                    width: 24,
                    margin: EdgeInsets.all(6),
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white,
                        width: selectColor == color ? 4 : 2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: brushWidthList.map((width) {
                return GestureDetector(
                  onTap: () {
                    brushWidth = width;
                    setState(() {});
                  },
                  child: Container(
                      height: 36,
                      width: 36,
                      margin: EdgeInsets.all(6),
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: brushWidth == width
                              ? Colors.white
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.brush_rounded,
                            size: 16,
                            color: brushWidth == width
                                ? selectColor
                                : Colors.white,
                          ),
                          Container(
                            color: brushWidth == width
                                ? selectColor
                                : Colors.white,
                            height: width,
                            width: 18,
                          ),
                        ],
                      )),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                child: Icon(Icons.save_alt_rounded),
                tooltip: '保存',
                heroTag: 'save',
                onPressed: () {
                  saveToImage();
                },
              ),
              SizedBox(width: 2),
              FloatingActionButton(
                child: Icon(Icons.format_paint_rounded),
                tooltip: '绘制',
                heroTag: 'draw',
                backgroundColor:
                    boradMode == BoradMode.Draw ? Colors.blue : Colors.grey,
                onPressed: () {
                  boradMode = BoradMode.Draw;
                  setState(() {});
                },
              ),
              SizedBox(width: 2),
              FloatingActionButton(
                child: Icon(
                  Icons.fullscreen_rounded,
                ),
                backgroundColor:
                    boradMode == BoradMode.Zoom ? Colors.blue : Colors.grey,
                tooltip: '缩放',
                heroTag: 'scale',
                onPressed: () {
                  boradMode = BoradMode.Zoom;
                  setState(() {});
                },
              ),
              SizedBox(width: 2),
              FloatingActionButton(
                child: Icon(Icons.undo_rounded),
                tooltip: '回退',
                heroTag: 'undo',
                backgroundColor:
                    paintList.isNotEmpty ? Colors.blue : Colors.grey,
                onPressed: () {
                  if (paintList.isNotEmpty) {
                    paintList.removeLast();
                    setState(() {});
                  }
                },
              ),
              SizedBox(width: 2),
              FloatingActionButton(
                child: Icon(
                  Icons.clear,
                ),
                tooltip: '清空',
                heroTag: 'clear',
                backgroundColor:
                    paintList.isNotEmpty ? Colors.blue : Colors.grey,
                onPressed: () {
                  paintList = [];
                  setState(() {});
                },
              ),
              SizedBox(width: 2),
              FloatingActionButton(
                child: Icon(
                  Icons.text_fields_rounded,
                  color: selectColor,
                ),
                tooltip: '文本',
                heroTag: 'text',
                onPressed: () {
                  showEditTextDialog();
                },
              ),
            ],
          ),
          SizedBox(width: 6),
        ],
      ),
    );
  }

  /// 处理点击事件
  void handleOnTap() {
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
          showEditTextDialog(drawText: item);
        } else {
          // 先设置为不选中状态
          _tempText?.selected = false;
          // 然后赋值设置为选中状态
          _tempText = item;
          _tempText.selected = true;
          setState(() {});
        }
        break;
      } else {
        debugPrint('onTapDown 未命中');
        item.selected = false;
        _tempText = null;
        setState(() {});
      }
    }
  }

  /// 处理缩放移动开始事件
  void handleOnScaleStart(ScaleStartDetails details) {
    _tmpFocal = details.focalPoint;
    if (_tempText != null && _tempText.selected) {
      _tmpMoveX = _tempText.offset.dx;
      _tmpMoveY = _tempText.offset.dy;
      _tmpScale = _tempText.scale;
    } else {
      _tmpMoveX = _moveX;
      _tmpMoveY = _moveY;
      _tmpScale = _scale;
      _tmpRotation = _rotation;
    }
  }

  /// 处理缩放移动更新事件
  void handleOnScaleUpdate(ScaleUpdateDetails details) {
    if (_tempText != null && _tempText.selected) {
      double textMoveX = _tmpMoveX + (details.focalPoint.dx - _tmpFocal.dx);
      double textMoveY = _tmpMoveY + (details.focalPoint.dy - _tmpFocal.dy);
      _tempText.offset = Offset(textMoveX, textMoveY);
      _tempText.scale = _tmpScale * details.scale;
    } else {
      _moveX = _tmpMoveX + (details.focalPoint.dx - _tmpFocal.dx) / _tmpScale;
      debugPrint(
          'onScaleUpdate _moveX:$_moveX _tmpMoveX:$_tmpMoveX _tmpFocal:${_tmpFocal.toString()} _tmpScale:$_tmpScale');
      _moveY = _tmpMoveY + (details.focalPoint.dy - _tmpFocal.dy) / _tmpScale;
      debugPrint(
          'onScaleUpdate _moveY:$_moveY _tmpMoveY:$_tmpMoveY _tmpFocal:${_tmpFocal.toString()} _tmpScale:$_tmpScale');
      _scale = _tmpScale * details.scale;
      _rotation = _tmpRotation + details.rotation;
    }

    setState(() {});
  }

  /// 处理滑动开始事件
  void handleOnPanStart() {
    _tempLine = DrawLine()
      ..color = selectColor
      ..lineWidth = brushWidth;
    paintList.add(_tempLine);
  }

  /// 处理滑动更新事件
  void handleOnPanUpdate(DragUpdateDetails details) {
    RenderBox renderBox = drawGestureKey.currentContext.findRenderObject();
    Offset localPos = renderBox.globalToLocal(details.globalPosition);
    if (_tempLine == null) {
      _tempLine = DrawLine();
      paintList.add(_tempLine);
    }
    _tempLine.linePath.add(localPos);
    paintList.last = _tempLine;
    setState(() {});
  }

  /// 现实文字输入框
  Future<void> showEditTextDialog({DrawText drawText}) async {
    //弹出文字输入框
    var result = await showDialog(
      context: context,
      builder: (context) {
        return EditTextPage(
          text: drawText?.text,
          color: drawText?.color,
        );
      },
    );
    // 获取文字结果
    if (result != null) {
      String text = result['text'];
      int colorValue = result['color'];
      debugPrint('showEditTextPage text:$text colorValue:$colorValue');
      Color textColor = Color(colorValue);
      if (drawText == null) {
        double padding = MediaQuery.of(context).padding.bottom;
        Offset center = MediaQuery.of(context).size.center(Offset(0, padding));
        DrawText newDrawText = DrawText()
          ..text = text ?? ''
          ..drawSize = Size(0, 0)
          ..offset = center
          ..fontSize = 14
          ..color = textColor;
        paintList.add(newDrawText);
      } else {
        drawText
          ..text = text
          ..color = textColor;
      }

      setState(() {});
    }
  }

  // 保存为图片
  Future<void> saveToImage() async {
    /// 恢复到默认状态
    _scale = 1.0;
    _moveX = 0;
    _moveY = 0;
    setState(() {});
    await Future.delayed(Duration(milliseconds: 300));

    /// 开始保存图片
    RenderRepaintBoundary boundary =
        drawToImageKey.currentContext.findRenderObject();
    ui.Image image = await boundary.toImage(pixelRatio: 3);
    ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData.buffer.asUint8List();
    print(pngBytes);

    /// 显示图片
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('保存的图片'),
          content: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey,
                width: 1,
              ),
            ),
            child: Image.memory(pngBytes),
          ),
        );
      },
    );
  }
}
