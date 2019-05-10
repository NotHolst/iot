import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:io_project_app/dashboard.dart';
import 'pairing.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PairingScreen(),
    );
  }
}
