import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

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
      'https://images.pexels.com/photos/12617812/pexels-photo-12617812.jpeg?cs=srgb&dl=pexels-maria-luiza-melo-12617812.jpg&fm=jpg';
  String imageUrl2 =
      'https://cdn.pixabay.com/photo/2017/07/04/10/07/board-2470557__340.jpg';
  String imageUrl3 =
      'https://cdn.pixabay.com/photo/2017/07/20/03/53/homework-2521144_1280.jpg';
  String imageUrl4 =
      'https://img.banjixiaoguanjia.com/app_image_5f2f7aab74eab167730f6b26_cos/8613979fa6193571e9373c936c4a363a_1660298899331.jpg?1660879803667';
  String imageUrl5 =
      'https://img.banjixiaoguanjia.com/app_image_5f2f7aab74eab167730f6b26_cos/03c5035b0cacba18b992260f4b8e5be6_1660298900012.jpg?1660879803667';
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

  /// 是否被 90度的奇数，就是90和270
  bool get is90 => (rotation ~/ (pi / 2)).isOdd;

  /// 绘制的key
  GlobalKey<FlutterPainterWidgetState> painterKey = GlobalKey();
  GlobalKey<FlutterPainterWidgetState> imgKey = GlobalKey();

  // 宽高
  double? width;
  double? height;

  @override
  void initState() {
    super.initState();
    getAbsoluteSize();
  }

  /// 获取最终图片的大小来设置画布的大小
  void getAbsoluteSize() async {
    await Future.delayed(Duration(milliseconds: 1000));
    Size? size = imgKey.currentContext?.size;
    if (size != null && size.width > 0 && size.height > 0) {
      width = size.width;
      height = size.height;
      setState(() {});
    } else {
      getAbsoluteSize();
    }
    print('FlutterPainter width: $width, height: $height');
  }

  /// 获取图片大小
  /// [return] 图片大小
  Size getImageSize() {
    if (width == null || height == null) {
      return Size.zero;
    }
    return is90 ? Size(height!, width!) : Size(width!, height!);
  }

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
              width: width,
              height: height,
              background: Image.network(
                imageUrl1,
                fit: BoxFit.cover,
                key: imgKey,
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
                            // 计算旋转
                            rotation = rotation - pi / 2;
                            painterKey.currentState
                                ?.setBackgroundRotation(rotation);
                            // 计算缩放
                            Size imgSize = getImageSize();
                            Size broadSize =
                                painterKey.currentState?.boradSize ?? Size.zero;
                            double scaleWidth = broadSize.width / imgSize.width;
                            double scaleHeight =
                                broadSize.height / imgSize.height;
                            double minScale = min(scaleWidth, scaleHeight);
                            // width = imgSize.width * minScale;
                            // height = imgSize.height * minScale;
                            painterKey.currentState?.setBgScale(minScale);
                            painterKey.currentState?.setScale(1);
                            painterKey.currentState?.setMove(0, 0);
                            print(
                                'FlutterPainter imgSize:$imgSize broadSize:$broadSize , minScale:$minScale scaleWidth:$scaleWidth scaleHeight:$scaleHeight');
                            setState(() {});
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
    Size? broadSize = imgKey.currentContext?.size ??
        MediaQueryData.fromWindow(ui.window).size;
    double moveX = painterKey.currentState?.moveX ?? 0;
    double moveY = painterKey.currentState?.moveY ?? 0;
    print(
        'broadSize:$broadSize moveX:$moveX moveY:$moveY size:${painterKey.currentContext?.size}');
    return broadSize.center(Offset.zero).translate(-moveX, -moveY);
  }
}
