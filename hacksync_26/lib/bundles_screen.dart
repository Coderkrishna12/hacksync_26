import 'package:flutter/material.dart';
// bundles_screen.dart
class BundlesScreen extends StatelessWidget {
  const BundlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bundles (Playlists)")),
      body: const Center(child: Text("Bundles content here", style: TextStyle(fontSize: 32))),
    );
  }
}