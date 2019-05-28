import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:io_project_app/components/CurveEditor.dart';
import 'package:io_project_app/sendingDialog.dart';

import 'package:charts_flutter/flutter.dart' as charts;

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
  final WRITE_CHARACTERISTIC = Guid('0000FFF3-0000-1000-8000-00805F9B34FB');
  final READ_CHARACTERISTIC = Guid('0000FFF4-0000-1000-8000-00805F9B34FB');

  var temperatureCurve = List<CurvePoint>();
  var temperatureChartData = List<ChartPoint>();
  var humidityCurve = List<CurvePoint>();
  var humidityChartData = List<ChartPoint>();
  var ambientLightCurve = List<CurvePoint>();
  var ambientLightChartData = List<ChartPoint>();

  var isDirty = false;

  BluetoothDeviceState deviceState = BluetoothDeviceState.disconnected;

  BluetoothService service;

  @override
  void initState() {
    super.initState();

    _localFile.then((file) => file.delete());

    flutterBlue.connect(widget.device).listen(
      (s) {
        setState(() => deviceState = s);
        if (s == BluetoothDeviceState.connected)
          widget.device.discoverServices().then((services) {
            service = services.firstWhere((s) => s.uuid == SERVICE_GUID);
            var c = service.characteristics
                .firstWhere((c) => c.uuid == READ_CHARACTERISTIC);
            widget.device.setNotifyValue(c, true);
            widget.device.onValueChanged(c).listen((data) {
              gatherData(data);
            });
          });
      },
    );
  }

  gatherData(List<int> data) async {
    var buffer = Uint8List.fromList(data).buffer;
    var bdata = ByteData.view(buffer);
    setState(() {
      var humidity = bdata.getFloat32(0, Endian.little);
      var temperature = bdata.getFloat32(4, Endian.little);
      var ambientLight = bdata.getFloat32(8, Endian.little);

      writeData(temperature, ambientLight, humidity);

      humidityChartData.add(ChartPoint(DateTime.now(), humidity));
      temperatureChartData.add(ChartPoint(DateTime.now(), temperature));
      ambientLightChartData.add(ChartPoint(DateTime.now(), ambientLight));

      if (humidityChartData.length > 5000) humidityChartData.removeAt(0);
      if (temperatureChartData.length > 5000) temperatureChartData.removeAt(0);
      if (ambientLightChartData.length > 5000)
        ambientLightChartData.removeAt(0);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future sendTemperature() {
    return Future.delayed(Duration(milliseconds: 10000), () {
      sendDataToDevice('st', temperatureCurve); // u = update | t = temperature
    });
  }

  Future sendHumidity() async {
    return Future.delayed(Duration(milliseconds: 10000), () {
      sendDataToDevice('sh', humidityCurve); // u = update | t = temperature
    });
  }

  Future sendAmbientLight() async {
    return Future.delayed(Duration(milliseconds: 10000), () {
      sendDataToDevice('sa', ambientLightCurve); // u = update | t = temperature
    });
  }

  sendDataToDevice(String command, List<CurvePoint> points) async {
    var c = service.characteristics
        .firstWhere((c) => c.uuid == WRITE_CHARACTERISTIC);

    var dataString = command;
    var xMax = 1440, yMax = 100.0;
    points.asMap().forEach((index, p) {
      var x = (p.x * xMax).round();
      var y = 100 - (p.y * yMax).round();
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
      await widget.device.writeCharacteristic(c, chunk);
    }
  }

  Future test() async {
    Future.delayed(Duration(seconds: 2), () {
      print('TEST FUNCTION END');
    });
  }

  int saveProgress = 0;
  saveChanges() async {
    showDialog(
        // barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: const Text('Sending data to device'),
            children: <Widget>[
              SendingDialog(
                [sendTemperature, sendHumidity, sendAmbientLight],
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

  List<charts.Series<ChartPoint, DateTime>> getDataSeries(
      String title, List<ChartPoint> data) {
    return [
      new charts.Series<ChartPoint, DateTime>(
        id: title,
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (ChartPoint sales, _) => sales.time,
        measureFn: (ChartPoint sales, _) => sales.value,
        data: data,
      )
    ];
  }

  shareData() async {
    var file = await _localFile;
    await Share.file(
        'Sensor Data', 'data.csv', file.readAsBytesSync(), 'text/csv');
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/data.txt');
  }

  Future<File> writeData(
      num temperature, num ambientLight, num humidity) async {
    final file = await _localFile;

    // Write the file
    var fileWrite = file.writeAsString(
      '$temperature;$ambientLight;$humidity\r\n',
      mode: FileMode.append,
    );
    return fileWrite;
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
              ),
              MaterialButton(
                child: Icon(
                  Icons.share,
                  color: Colors.white,
                ),
                onPressed: () => shareData(),
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
            title: Text(
              '${widget.device.name}',
              style: TextStyle(
                  color: deviceState == BluetoothDeviceState.connected
                      ? Colors.white
                      : Colors.red),
            ),
          ),
          body: Column(
            children: <Widget>[
              Expanded(
                child: TabBarView(
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
                            Expanded(
                              child: charts.TimeSeriesChart(
                                getDataSeries(
                                    "Temperature", temperatureChartData),
                                animate: false,
                              ),
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
                                  humidityCurve
                                      .sort((p1, p2) => p1.x.compareTo(p2.x));
                                  isDirty = true;
                                });
                              },
                            ),
                            Expanded(
                              child: charts.TimeSeriesChart(
                                getDataSeries("Humidity", humidityChartData),
                                animate: false,
                              ),
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
                            ),
                            Expanded(
                              child: charts.TimeSeriesChart(
                                getDataSeries(
                                    "Ambient Light", ambientLightChartData),
                                animate: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
    );
  }
}

class ChartPoint {
  DateTime time;
  num value;

  ChartPoint(this.time, this.value);
}
