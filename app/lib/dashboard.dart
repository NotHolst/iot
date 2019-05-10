import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:io_project_app/components/CurveEditor.dart';
import 'package:io_project_app/sendingDialog.dart';

class Dashboard extends StatefulWidget {
  Dashboard({Key key, @required this.device}) : super(key: key);

  final BluetoothDevice device;

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  FlutterBlue flutterBlue = FlutterBlue.instance;

  final SERVICE_GUID = Guid('0000FFF0-0000-1000-8000-00805F9B34FB');
  final CHARACTERISTIC_GUID = Guid('0000FFF3-0000-1000-8000-00805F9B34FB');

  var temperatureCurve = List<CurvePoint>();
  var humidityCurve = List<CurvePoint>();
  var ambientLightCurve = List<CurvePoint>();

  var isDirty = false;

  StreamSubscription<BluetoothDeviceState> deviceState;

  BluetoothService service;

  @override
  void initState() {
    super.initState();
    deviceState = flutterBlue.connect(widget.device).listen(
      (s) {
        if (s == BluetoothDeviceState.connected)
          widget.device.discoverServices().then((services) {
            service = services.firstWhere((s) => s.uuid == SERVICE_GUID);
          });
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future sendTemperature() async {
    sendDataToDevice(temperatureCurve); // u = update | t = temperature

    return Future.delayed(Duration(milliseconds: Random().nextInt(2500)));
  }

  Future sendHumidity() async {
    return Future.delayed(Duration(milliseconds: Random().nextInt(2500)));
  }

  Future sendAmbientLight() async {
    return Future.delayed(Duration(milliseconds: Random().nextInt(2500)));
  }

  sendDataToDevice(List<CurvePoint> points) async {
    var c = service.characteristics
        .firstWhere((c) => c.uuid == CHARACTERISTIC_GUID);

    var dataString = 's';
    var xMax = 1440, yMax = 100.0;
    points.asMap().forEach((index, p) {
      var x = (p.x * xMax).round();
      var y = (p.y * yMax).round();
      dataString += '$x,$y ';

      if (index == points.length - 1) dataString += "e";
    });

    var enc = ascii.encode(dataString);
    var data = new Uint8List(enc.length);

    for (int i = 0; i < enc.length; i++) {
      data[i] = enc[i];
    }

    var chunkSize = 19;
    for (int i = 0; i < data.length; i += chunkSize) {
      var end = (i + chunkSize > data.length) ? data.length : i + chunkSize;
      var chunk = data.sublist(i, end).toList();
      chunk.insert(0, chunk.length);
      print(chunk);
      await widget.device.writeCharacteristic(c, chunk);
    }
  }

  saveChanges() {
    showDialog(
        // barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: const Text('Sending data to device'),
            children: <Widget>[
              SendingDialog(
                [
                  sendTemperature(),
                  sendHumidity(),
                  sendAmbientLight(),
                ],
                onCompleted: () {
                  Navigator.pop(context);
                },
              )
            ],
          );
        });
    setState(() {
      isDirty = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          actions: <Widget>[
            MaterialButton(
              child: isDirty
                  ? Icon(
                      Icons.save,
                      color: Colors.white,
                    )
                  : Text(
                      'Updated',
                      style: TextStyle(color: Colors.white),
                    ),
              onPressed: () {
                saveChanges();
              },
            )
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: 'Temperature'),
              Tab(
                text: 'Humidity',
              ),
              Tab(
                text: 'Light',
              ),
            ],
          ),
          title: Text('${widget.device.name}'),
        ),
        body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            Container(
              padding: EdgeInsets.all(16),
              child: Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      leading: Icon(Icons.perm_data_setting),
                      title: Text('Temperature'),
                      trailing: MaterialButton(
                        child: Icon(Icons.refresh),
                        onPressed: () {},
                      ),
                    ),
                    CurveEditor(
                      onCurveChanged: (points) {
                        setState(() {
                          temperatureCurve = points;
                          temperatureCurve
                              .sort((p1, p2) => p1.x.compareTo(p2.x));
                          isDirty = true;
                        });
                      },
                    ),
                    Text('${temperatureCurve.length}')
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              child: Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      leading: Icon(Icons.perm_data_setting),
                      title: Text('Humidity'),
                      trailing: MaterialButton(
                        child: Icon(Icons.refresh),
                        onPressed: () {},
                      ),
                    ),
                    CurveEditor(
                      onCurveChanged: (points) {
                        setState(() {
                          humidityCurve = points;
                          humidityCurve.sort((p1, p2) => p1.x.compareTo(p2.x));
                          isDirty = true;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              child: Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      leading: Icon(Icons.perm_data_setting),
                      title: Text('Light'),
                      trailing: MaterialButton(
                        child: Icon(Icons.refresh),
                        onPressed: () {},
                      ),
                    ),
                    CurveEditor(
                      onCurveChanged: (points) {
                        setState(() {
                          ambientLightCurve = points;
                          ambientLightCurve
                              .sort((p1, p2) => p1.x.compareTo(p2.x));
                          isDirty = true;
                        });
                      },
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
