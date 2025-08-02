 import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const DevChatApp());
}

class DevChatApp extends StatelessWidget {
  const DevChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevChat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
