import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class CurveEditor extends StatefulWidget {
  @override
  _CurveEditorState createState() => _CurveEditorState();
}

class CurvePoint {
  CurvePoint(this.x, this.y);
  double x, y;

  CurvePoint operator -(CurvePoint other) {
    return CurvePoint(this.x - other.x, this.y - other.y);
  }

  CurvePoint operator +(CurvePoint other) {
    return CurvePoint(this.x + other.x, this.y + other.y);
  }

  CurvePoint operator *(CurvePoint other) {
    return CurvePoint(this.x * other.x, this.y * other.y);
  }
}

class _CurveEditorState extends State<CurveEditor> {
  var offset = Offset.fromDirection(.2, 4);

  var points = List<CurvePoint>();
  double editorWidth = 0, editorHeight = 0;
  CurvePoint currentPoint;

  var canvasStack = GlobalKey(debugLabel: 'CanvasStack');

  @override
  initState() {
    super.initState();
    points.addAll([
      CurvePoint(0.2, 0.3),
      CurvePoint(0.6, 0.6),
      CurvePoint(0.6, 0.6),
      CurvePoint(0.2, 0.3),
      CurvePoint(0.6, 0.6),
      CurvePoint(0.6, 0.6),
      CurvePoint(0.6, 0.6),
    ]);
  }

  Future<void> loadCurves() {
    return Future.delayed(Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    var pointsCurve = List<Widget>();

    pointsCurve.add(CustomPaint(
      painter: CurvePainter(points, editorWidth, editorHeight),
      child: Container(
        height: 300.0,
      ),
    ));

    points.asMap().forEach(
      (index, p) {
        pointsCurve.add(
          Positioned(
            left: p.x * editorWidth - 16,
            top: p.y * editorHeight - 16,
            child: GestureDetector(
              onPanStart: (details) => currentPoint = p,
              onPanUpdate: (details) {
                setState(() {
                  RenderBox box = canvasStack.currentContext.findRenderObject();
                  editorWidth = box.size.width;
                  editorHeight = box.size.height;
                  var localOffset = box.globalToLocal(details.globalPosition);
                  currentPoint.x = max(min(localOffset.dx, box.size.width), 0) /
                      box.size.width;
                  currentPoint.y =
                      max(min(localOffset.dy, box.size.height), 0) /
                          box.size.height;
                });
              },
              onPanEnd: (details) {
                setState(() {
                  currentPoint = null;
                });
              },
              onLongPress: () {
                if (points.length <= 1) return;
                setState(() {
                  points.removeAt(index);
                });
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor:
                    p == currentPoint ? Colors.lightBlueAccent : Colors.blue,
              ),
            ),
          ),
        );
      },
    );

    return SizedBox(
      height: 200,
      child: GestureDetector(
        child: Stack(key: canvasStack, children: pointsCurve),
        onScaleUpdate: (details) {
          print(details.horizontalScale);
        },
        onLongPressDragStart: (details) {
          setState(() {
            RenderBox box = canvasStack.currentContext.findRenderObject();
            editorWidth = box.size.width;
            editorHeight = box.size.height;
            var localOffset = box.globalToLocal(details.globalPosition);
            points.add(CurvePoint(
                localOffset.dx / editorWidth, localOffset.dy / editorHeight));
          });
        },
      ),
    );
  }
}

class CurvePainter extends CustomPainter {
  CurvePainter(this._points, this.editorWidth, this.editorHeight) {}

  List<CurvePoint> _points;
  double editorWidth = 0, editorHeight = 0;
  @override
  void paint(Canvas canvas, Size size) {
    var gridPaint = Paint();
    gridPaint.color = Colors.black38;
    var resolution = 8;

    for (double x = editorHeight / resolution;
        x < editorWidth;
        x += editorHeight / resolution) {
      canvas.drawLine(Offset(x, 0), Offset(x, editorHeight - 24), gridPaint);

      var builder = ui.ParagraphBuilder(ui.ParagraphStyle(
          textAlign: TextAlign.center,
          fontFamily: "RobotoMedium",
          fontSize: 14.0,
          height: 6))
        ..pushStyle(ui.TextStyle(color: Colors.black));
      builder.addText("2");

      canvas.drawParagraph(builder.build(), Offset(x, x));
    }

    var sorted = _points.toList();
    sorted.sort((p1, p2) => p1.x.compareTo(p2.x));
    var path = Path();
    path.moveTo(0, sorted[0].y * editorHeight);
    path.lineTo(sorted[0].x * editorWidth, sorted[0].y * editorHeight);
    for (int i = 1; i < sorted.length; i++) {
      path.lineTo(sorted[i].x * editorWidth, sorted[i].y * editorHeight);
    }
    path.lineTo(editorWidth, sorted[sorted.length - 1].y * editorHeight);
    var paint = Paint();
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 5;
    paint.color = Colors.blue[200];
    canvas.drawPath(path, paint);
  }

  var painted = false;
  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
