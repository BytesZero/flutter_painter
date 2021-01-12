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
        child: Center(
          child: Transform(
            transform: matrix4,
            alignment: FractionalOffset.center,
            child: Stack(
              children: [
                Image.asset(imageUrl),
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
                            Offset lp = _tempTapDownDetails.localPosition;
                            debugPrint('onTapDown details:${lp.toString()}');
                            debugPrint(
                                'onTapDown _tempText:${_tempText.toString()}');
                            if (_tempText != null) {
                              /// 计算是否命中删除区域
                              double delRadius = _tempText.delRadius;
                              Rect tempTextRect = _tempText.textRect;
                              // tempTextRect = tempTextRect.deflate(
                              //     (tempTextRect.right - tempTextRect.left) *
                              //         _tempText.scale);
                              if (_tempText.selected &&
                                  lp.dx >= (tempTextRect.left - delRadius) &&
                                  lp.dx <= (tempTextRect.left + delRadius) &&
                                  lp.dy >= (tempTextRect.top - delRadius) &&
                                  lp.dy <= (tempTextRect.top + delRadius)) {
                                paintList.remove(_tempText);
                                _tempText = null;
                                setState(() {});
                                return;
                              } else {
                                _tempText.selected = false;
                              }
                            }

                            /// 只获取文字
                            var textList = paintList.whereType<DrawText>();
                            // 遍历查看是否命中事件
                            for (var item in textList) {
                              Rect textRect = item.textRect;
                              //计算是否命中事件
                              if (lp.dx >= textRect.left &&
                                  lp.dx <= textRect.right &&
                                  lp.dy >= textRect.top &&
                                  lp.dy <= textRect.bottom) {
                                debugPrint('onTapDown 命中🎯');
                                _tempText = item;
                                _tempText.selected = true;
                                setState(() {});
                                break;
                              } else {
                                debugPrint('onTapDown 未命中');
                                _tempText = null;
                                setState(() {});
                              }
                            }
                          },
                          onScaleStart: (details) {
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

                            debugPrint(
                                'onScaleStart _tmpFocal:$_tmpFocal _tmpMoveX:$_tmpMoveX _tmpMoveY:$_tmpMoveY _tmpScale:$_tmpScale _tmpRotation:$_tmpRotation details:${details.toString()}');
                          },
                          onScaleUpdate: (details) {
                            if (_tempText != null && _tempText.selected) {
                              double textMoveX = _tmpMoveX +
                                  (details.focalPoint.dx - _tmpFocal.dx) /
                                      _tmpScale;
                              debugPrint(
                                  'onScaleUpdate _moveX:$_moveX _tmpMoveX:$_tmpMoveX _tmpFocal:${_tmpFocal.toString()} _tmpScale:$_tmpScale');
                              double textMoveY = _tmpMoveY +
                                  (details.focalPoint.dy - _tmpFocal.dy) /
                                      _tmpScale;
                              _tempText.offset = Offset(textMoveX, textMoveY);
                              // _tempText.scale = _tmpScale * details.scale;
                            } else {
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
                            }

                            setState(() {});
                          },
                        )
                      : GestureDetector(
                          key: drawGestureKey,
                          onPanStart: (details) {
                            _tempLine = DrawLine();
                            _tempLine.color = selectColor;
                            paintList.add(_tempLine);
                          },
                          onPanUpdate: (details) {
                            RenderBox renderBox = drawGestureKey.currentContext
                                .findRenderObject();
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
                        ),
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
          Container(
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
                    ..text = '花熊是\n最可爱的狗狗🐶'
                    ..drawSize = Size(0, 0)
                    ..offset = Offset(80, 80)
                    ..fontSize = (12 + paintList.length.toDouble())
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
