import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth_screen(auth).dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyA0scpMOa2y0XHYLMcY7HGQZCMmrOF1eSw",
      authDomain: "openintern-22f00.firebaseapp.com",
      projectId: "openintern-22f00",
      storageBucket: "openintern-22f00.appspot.com",
      messagingSenderId: "402111961084",
      appId: "1:402111961084:web:d30332661f94dfbfd7c479", // ✅ Check if this matches your Firebase Console Web App
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth Demo',
      home: AuthScreen(),
    );
  }
}
