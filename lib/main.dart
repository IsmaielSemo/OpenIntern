import 'package:flutter/material.dart';
//import 'loginscreen.dart'; // Import the LoginScreen
import 'signupscreen.dart'; // Import the SignupScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OpenIntern',
      theme: ThemeData(
        primaryColor: const Color(0xFF4285F4),
        scaffoldBackgroundColor: Colors.grey[200],
      ),
   //   home: const LoginScreen(),  // Set LoginScreen as the home screen
      home: const SignupScreen(),
    );
  }
}

