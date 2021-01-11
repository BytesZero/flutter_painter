import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_painter_example/draw/draw_text.dart';
import 'draw/draw_borad.dart';
import 'draw/draw_line.dart';
import 'draw/base_draw.dart';

/// 首页
class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  String imageUrl = 'assets/images/huaxiong.jpeg';

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
  Color selectColor = Colors.red;
  // 绘制集合
  List<BaseDraw> paintList = [];
  DrawLine _tempLine;

  @override
  bool get wantKeepAlive => true;

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
        child: Center(
          child: Transform(
            transform: matrix4,
            alignment: FractionalOffset.center,
            child: Stack(
              children: [
                Image.asset(imageUrl),
                boradMode == BoradMode.Draw
                    ? GestureDetector(
                        key: drawGestureKey,
                        onPanStart: (details) {
                          _tempLine = DrawLine();
                          _tempLine.color = selectColor;
                          paintList.add(_tempLine);
                        },
                        onPanUpdate: (details) {
                          RenderBox renderBox =
                              drawGestureKey.currentContext.findRenderObject();
                          Offset localPos =
                              renderBox.globalToLocal(details.globalPosition);
                          if (_tempLine == null) {
                            _tempLine = DrawLine();
                            paintList.add(_tempLine);
                          }
                          _tempLine.linePath.add(localPos);
                          paintList.last = _tempLine;
                          setState(() {});
                        },
                        onPanEnd: (details) {
                          _tempLine = null;
                        },
                      )
                    : SizedBox(),
                boradMode == BoradMode.Zoom
                    ? GestureDetector(
                        onScaleStart: (details) {
                          _tmpFocal = details.focalPoint;
                          _tmpMoveX = _moveX;
                          _tmpMoveY = _moveY;
                          _tmpScale = _scale;
                          _tmpRotation = _rotation;

                          debugPrint(
                              'onScaleStart _tmpFocal:$_tmpFocal _tmpMoveX:$_tmpMoveX _tmpMoveY:$_tmpMoveY _tmpScale:$_tmpScale _tmpRotation:$_tmpRotation details:${details.toString()}');
                        },
                        onScaleUpdate: (details) {
                          debugPrint(
                              'onScaleUpdate details:${details.toString()}');
                          _moveX = _tmpMoveX +
                              (details.focalPoint.dx - _tmpFocal.dx) /
                                  _tmpScale;
                          debugPrint(
                              'onScaleUpdate _moveX:$_moveX _tmpMoveX:$_tmpMoveX _tmpFocal:${_tmpFocal.toString()} _tmpScale:$_tmpScale');
                          _moveY = _tmpMoveY +
                              (details.focalPoint.dy - _tmpFocal.dy) /
                                  _tmpScale;
                          debugPrint(
                              'onScaleUpdate _moveY:$_moveY _tmpMoveY:$_tmpMoveY _tmpFocal:${_tmpFocal.toString()} _tmpScale:$_tmpScale');
                          _scale = _tmpScale * details.scale;
                          _rotation = _tmpRotation + details.rotation;
                          setState(() {});
                        },
                      )
                    : SizedBox(),
                CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: DrawBorad(paintList: paintList),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Visibility(
            visible: true,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.all(10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: colorList.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectColor = color;
                      });
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
          ),
          SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                child: Icon(Icons.format_paint_rounded),
                tooltip: '绘制',
                backgroundColor:
                    boradMode == BoradMode.Draw ? Colors.blue : Colors.grey,
                onPressed: () {
                  boradMode = BoradMode.Draw;
                  setState(() {});
                },
              ),
              SizedBox(width: 6),
              FloatingActionButton(
                child: Icon(
                  Icons.fullscreen_rounded,
                ),
                backgroundColor:
                    boradMode == BoradMode.Zoom ? Colors.blue : Colors.grey,
                tooltip: '缩放',
                onPressed: () {
                  boradMode = BoradMode.Zoom;
                  setState(() {});
                },
              ),
              SizedBox(width: 6),
              FloatingActionButton(
                child: Icon(Icons.undo_rounded),
                tooltip: '回退',
                backgroundColor:
                    paintList.isNotEmpty ? Colors.blue : Colors.grey,
                onPressed: () {
                  if (paintList.isNotEmpty) {
                    paintList.removeLast();
                    setState(() {});
                  }
                },
              ),
              SizedBox(width: 6),
              FloatingActionButton(
                child: Icon(
                  Icons.clear,
                ),
                tooltip: '清空',
                backgroundColor:
                    paintList.isNotEmpty ? Colors.blue : Colors.grey,
                onPressed: () {
                  paintList = [];
                  setState(() {});
                },
              ),
              SizedBox(width: 6),
              FloatingActionButton(
                child: Icon(
                  Icons.text_fields_rounded,
                  color: selectColor,
                ),
                tooltip: '文本',
                onPressed: () {
                  DrawText drawText = DrawText()
                    ..text =
                        '花熊使\n用低级方法时dart:ui，习惯上以前缀这些类ui.。\n这也有助于解决命名冲突。例如，TextStyle还可以在绘画库中定义。如果使用了TextStyle，则您需要为单个样式dart:ui使用编码，TextStyle().getTextStyle()或TextStyle().build()递归地应用样式树。'
                    ..drawSize = Size(100, 100)
                    ..offset = Offset(80, 80)
                    ..color = selectColor;
                  paintList.add(drawText);
                  setState(() {});
                },
              ),
            ],
          ),
          SizedBox(width: 6),
        ],
      ),
    );
  }
}
