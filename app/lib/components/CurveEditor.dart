import 'dart:math';

import 'package:flutter/material.dart';

class CurveEditor extends StatefulWidget {
  @override
  _CurveEditorState createState() => _CurveEditorState();
}

class CurvePoint {}

class _CurveEditorState extends State<CurveEditor> {
  var offset = Offset.fromDirection(.2, 4);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: offset.dx,
            top: offset.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  offset = Offset(
                    max(offset.dx + details.delta.dx, 0),
                    max(offset.dy + details.delta.dy, 0),
                  );
                  print(offset);
                });
              },
              child: CircleAvatar(
                backgroundColor: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
