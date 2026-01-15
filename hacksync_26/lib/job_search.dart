import 'package:flutter/material.dart';
// job_search.dart
class JobSearch extends StatelessWidget {
  const JobSearch({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Job Search")),
      body: const Center(child: Text("Job search content here", style: TextStyle(fontSize: 32))),
    );
  }
}