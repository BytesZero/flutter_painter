import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_painter/flutter_painter.dart';

import 'edit_text_page.dart';

/// 首页
class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String imageUrl1 =
      'https://cdn.pixabay.com/photo/2021/01/11/13/28/cross-country-skiing-5908416_1280.jpg';
  String imageUrl2 =
      'https://cdn.pixabay.com/photo/2017/07/04/10/07/board-2470557__340.jpg';
  String imageUrl3 =
      'https://cdn.pixabay.com/photo/2017/07/20/03/53/homework-2521144_1280.jpg';
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
  double brushWidth = 2;
  // 笔刷粗细列表
  List<double> brushWidthList = [
    1,
    2,
    4,
    6,
    8,
  ];

  // 图片资源列表
  List<String> imageList = [
    'assets/icons/icon_shoubiao.png',
    'assets/icons/icon_coffe.png',
    'assets/icons/icon_bangbangtang.png',
    'assets/icons/icon_shuibei.png',
  ];

  /// 旋转角度
  double rotation = 0.0;

  /// 绘制的key
  GlobalKey<FlutterPainterWidgetState> painterKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Flutter Painter Demo'),
        ),
        body: Stack(
          children: [
            FlutterPainterWidget(
              key: painterKey,
              background: Center(
                child: Image.network(
                  imageUrl3,
                  fit: BoxFit.cover,
                ),
              ),
              onTapText: (item) {
                showEditTextDialog(drawText: item);
              },
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedOpacity(
                      duration: Duration(milliseconds: 600),
                      opacity: 1,
                      child: Container(
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
                                setState(() {});
                                painterKey.currentState?.setBrushColor(color);
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
                    SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding:
                          EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: brushWidthList.map((width) {
                          return GestureDetector(
                            onTap: () {
                              brushWidth = width;
                              setState(() {});
                              painterKey.currentState?.setBrushWidth(width);
                            },
                            child: Container(
                                height: 36,
                                width: 36,
                                margin: EdgeInsets.all(6),
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
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
                                          : Colors.black54,
                                    ),
                                    Container(
                                      height: width,
                                      width: 18,
                                      decoration: BoxDecoration(
                                        color: brushWidth == width
                                            ? selectColor
                                            : Colors.black87,
                                        borderRadius:
                                            BorderRadius.circular(width),
                                      ),
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
                          child: Icon(Icons.crop_rotate_rounded),
                          tooltip: '旋转',
                          heroTag: 'rotate',
                          onPressed: () {
                            painterKey.currentState?.clearDraw();
                            rotation = rotation - pi / 2;
                            painterKey.currentState
                                ?.setBackgroundRotation(rotation);
                          },
                        ),
                        SizedBox(width: 2),
                        FloatingActionButton(
                          child: Icon(Icons.undo_rounded),
                          tooltip: '回退',
                          heroTag: 'undo',
                          onPressed: () {
                            painterKey.currentState?.undo();
                          },
                        ),
                        SizedBox(width: 2),
                        FloatingActionButton(
                          child: Icon(Icons.ac_unit_rounded),
                          tooltip: '橡皮擦',
                          heroTag: 'erase',
                          onPressed: () {
                            painterKey.currentState?.setEraseMode(true);
                            painterKey.currentState?.setEraseWidth(20);
                          },
                        ),
                        SizedBox(width: 2),
                        FloatingActionButton(
                          child: Icon(
                            Icons.clear,
                          ),
                          tooltip: '清空',
                          heroTag: 'clear',
                          onPressed: () {
                            painterKey.currentState?.clearDraw();
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
              ),
            ),
            Positioned(
              right: 0,
              bottom: MediaQuery.of(context).size.height / 2 - 90,
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: imageList.map((img) {
                      return GestureDetector(
                        onTap: () {
                          Offset center = getCurrentCenterOffset();
                          painterKey.currentState!.addImageAsset(
                            imgPath: img,
                            offset: center.translate(-60, -60),
                            drawSize: Size(120, 120),
                          );
                        },
                        child: Image.asset(
                          img,
                          width: 40,
                          height: 40,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            )
          ],
        ));
  }

  /// 现实文字输入框
  Future<void> showEditTextDialog({DrawText? drawText}) async {
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
      String? text = result['text'];
      int colorValue = result['color'];
      debugPrint('showEditTextPage text:$text colorValue:$colorValue');
      if (text == null) {
        print('text is null');
        return;
      }
      // 这里加个演示，防止获取到的布局大小是键盘弹起后的大小，高度会错误，导致中心点不对
      await Future.delayed(Duration(milliseconds: 600));
      Color textColor = Color(colorValue);
      if (drawText == null) {
        Offset center = getCurrentCenterOffset();
        center = center.translate(-14 * (text.length.clamp(1, 30)) / 4, -20);
        print('center:$center');
        DrawText newDrawText = DrawText()
          ..text = text
          ..drawSize = Size.zero
          ..offset = center
          ..fontSize = 14
          ..color = textColor
          ..selected = true;
        painterKey.currentState?.addText(newDrawText);
      } else {
        drawText
          ..text = text
          ..color = textColor;
      }
    }
  }

  // 保存为图片
  Future<void> saveToImage() async {
    Uint8List pngBytes = (await painterKey.currentState?.getImage())!;

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

  /// 获取当前中心位置
  Offset getCurrentCenterOffset() {
    Size? broadSize = painterKey.currentContext?.size ??
        MediaQueryData.fromWindow(window).size;
    double moveX = painterKey.currentState?.moveX ?? 0;
    double moveY = painterKey.currentState?.moveY ?? 0;
    print('broadSize:$broadSize moveX:$moveX moveY:$moveY');
    return broadSize.center(Offset.zero).translate(-moveX, -moveY);
  }
}
