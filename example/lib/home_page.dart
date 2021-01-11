import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// 首页
class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  String imageUrl = 'assets/images/huaxiong.jpeg';

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
                GestureDetector(
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
                    _moveX = _tmpMoveX +
                        (details.focalPoint.dx - _tmpFocal.dx) / _tmpScale;
                    _moveY = _tmpMoveY +
                        (details.focalPoint.dy - _tmpFocal.dy) / _tmpScale;
                    _scale = _tmpScale * details.scale;
                    _rotation = _tmpRotation + details.rotation;
                    setState(() {});
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
