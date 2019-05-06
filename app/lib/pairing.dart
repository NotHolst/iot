import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:io_project_app/dashboard.dart';
// import 'package:flutter_nfc_reader/flutter_nfc_reader.dart';

class PairingScreen extends StatefulWidget {
  @override
  _PairingScreenState createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  StreamSubscription<ScanResult> _scanSubscription;

  List<BluetoothDevice> _bluetoothDevices = List<BluetoothDevice>();
  // NfcData _nfcData;
  // Future<void> startNFC() async {
  //   setState(() {
  //     _nfcData = NfcData();
  //     _nfcData.status = NFCStatus.reading;
  //   });

  //   print('NFC: Scan started');

  //   print('NFC: Scan readed NFC tag');
  //   FlutterNfcReader.read.listen((response) {
  //     setState(() {
  //       print(response);
  //       _nfcData = response;
  //     });
  //   });
  // }

  startBLEScan() {
    _scanSubscription = flutterBlue.scan().listen(onDeviceDiscovered);
  }

  onDeviceDiscovered(ScanResult scanResult) {
    setState(() {
      if (scanResult.device.name != "" &&
          !_bluetoothDevices.any((d) => d.id.id == scanResult.device.id.id))
        _bluetoothDevices.add(scanResult.device);
      _bluetoothDevices.sort((d1, d2) => d2.name.length - d1.name.length);
    });
  }

  connectToDevice(BluetoothDevice device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Dashboard(
              device: device,
            ),
      ),
    );
  }

  @override
  initState() {
    super.initState();
    // startNFC();
    startBLEScan();
  }

  Widget deviceList() {
    return SizedBox(
        height: 300,
        child: RefreshIndicator(
          child: ListView.builder(
            itemCount: _bluetoothDevices.length,
            itemBuilder: (BuildContext ctxt, int index) {
              var device = _bluetoothDevices[index];
              return ListTile(
                leading: Icon(Icons.bluetooth),
                title: Text('${device.name}'),
                subtitle: Text('${device.id}'),
                onTap: () => connectToDevice(device),
              );
            },
          ),
          onRefresh: () {
            var loading = Future.delayed(Duration(seconds: 1));
            print('didthething');
            return loading;
          },
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.bluetooth_searching,
              color: Colors.blueAccent,
              size: 100,
            ),
            Container(
              padding: EdgeInsets.all(30),
              child: Card(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      title: Text(
                        'Select your IoT device',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    deviceList()
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
