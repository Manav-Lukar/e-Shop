import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lingopanda_assignment/screens/login_page.dart';
import 'package:lingopanda_assignment/screens/signup_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lingopanda Assignment',
      theme: ThemeData(
      
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
    );
  }
}
