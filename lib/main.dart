import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const HelvarNetApp());
}

class HelvarNetApp extends StatelessWidget {
  const HelvarNetApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HelvarNet Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}
