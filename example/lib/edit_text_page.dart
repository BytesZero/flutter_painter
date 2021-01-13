import 'package:flutter/material.dart';

/// 文字编辑页面
class EditTextPage extends StatefulWidget {
  EditTextPage({Key key, this.text = '', this.color = Colors.red})
      : super(key: key);
  // 文字
  final String text;
  // 颜色
  final Color color;

  @override
  _EditTextPageState createState() => _EditTextPageState();
}

class _EditTextPageState extends State<EditTextPage> {
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

  TextEditingController _editingController;

  @override
  void initState() {
    // 设置颜色
    selectColor = widget.color ?? Colors.red;
    // 设置文字
    _editingController = TextEditingController(text: widget.text ?? '');

    super.initState();
  }

  @override
  void dispose() {
    _editingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('编辑文字'),
        actions: [
          TextButton(
            onPressed: () {
              popPage(context);
            },
            child: Text('保存'),
          )
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          popPage(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: TextField(
              controller: _editingController,
              minLines: 1,
              maxLines: 8,
              autofocus: true,
              cursorHeight: 40,
              style: TextStyle(
                fontSize: 24,
                color: selectColor,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
            ),
          ),
        ),
      ),
      bottomSheet: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
        ),
        padding: EdgeInsets.all(10),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: colorList.map((color) {
            return GestureDetector(
              onTap: () {
                selectColor = color;
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
    );
  }

  void popPage(BuildContext context) {
    Navigator.pop(context, {
      'text': _editingController?.text ?? '',
      'color': selectColor.value,
    });
  }
}
