import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './screens/output_screen.dart';
import './screens/scanner.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIOverlays([]);
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "InvoiceMate",
      initialRoute: '/',
      routes: {
        '/': (context) => MenuDashboardPage(),
      },
    ),
  );
}
