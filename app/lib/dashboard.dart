import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:io_project_app/components/CurveEditor.dart';

class Dashboard extends StatefulWidget {
  Dashboard({Key key, @required this.device}) : super(key: key);

  BluetoothDevice device;

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.device.name}'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(16),
            child: Card(
              child: CurveEditor(),
            ),
          )
        ],
      ),
    );
  }
}
