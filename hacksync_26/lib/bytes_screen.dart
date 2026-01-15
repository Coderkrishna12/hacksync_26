import 'package:flutter/material.dart';

// bytes_screen.dart
class BytesScreen extends StatelessWidget {
  const BytesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bytes (Videos)")),
      body: const Center(child: Text("Bytes content here", style: TextStyle(fontSize: 32))),
    );
  }
}