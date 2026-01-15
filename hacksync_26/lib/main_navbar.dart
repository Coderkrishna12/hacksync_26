// // main_navigation.dart  (updated – now the root shell with persistent bottom nav)
// import 'package:flutter/material.dart';

// import 'home_screen.dart' hide ProfileScreen;  // Keep hide if needed, but now HomeScreen is body-only
// import 'bundles_screen.dart';
// import 'job_search.dart';
// import 'profile_screen.dart';

// class MainNavigation extends StatefulWidget {
//   const MainNavigation({super.key});

//   @override
//   State<MainNavigation> createState() => _MainNavigationState();
// }

// class _MainNavigationState extends State<MainNavigation> {
//   int _index = 0;

//   final List<String> _titles = ["Bytes", "Bundles", "Jobs", "Profile"];

//   // List of tab contents (no Scaffold inside them)
//   final List<Widget> _tabContents = [
//     const HomeScreen(),          // index 0
//     const BundlesScreen(),       // index 1
//     const JobSearch(),           // index 2
//     const ProfileScreen(),       // index 3
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_titles[_index]),
//         centerTitle: true,
//       ),
//       body: IndexedStack(
//         index: _index,
//         children: _tabContents,
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _index,
//         type: BottomNavigationBarType.fixed,
//         selectedItemColor: const Color(0xFF2563EB),  // Match your app theme
//         unselectedItemColor: Colors.grey,
//         backgroundColor: Colors.white,
//         elevation: 8,
//         onTap: (i) => setState(() => _index = i),
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.play_arrow_rounded), label: "Bytes"),
//           BottomNavigationBarItem(icon: Icon(Icons.playlist_play_rounded), label: "Bundles"),
//           BottomNavigationBarItem(icon: Icon(Icons.work_rounded), label: "Jobs"),
//           BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'bundles_screen.dart';
import 'job_search.dart';
import 'profile_screen.dart';
import 'skills.dart';
import 'video_conference.dart'; // ← add correct import for MeetingSchedulerScreen

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  final List<String> _titles = [
    "Bytes",
    "Bundles",
    "Jobs",
    "Profile",
    "Career",
  ];

  final List<Widget> _tabContents = [
    const BytesFeedContent(), // 0 – assuming this one is const / stateless & ok
    const QuickMeetingScreen(),
    const JobsSection(), // 2
    const ProfileScreen(), // 3
    const SkillsWorkflow(), // 4
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        centerTitle: true,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: IndexedStack(index: _index, children: _tabContents),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.play_arrow_rounded),
            label: "Bytes",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.playlist_play_rounded),
            label: "Bundles",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_rounded),
            label: "Jobs",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: "Profile",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: "Career"),
        ],
      ),
    );
  }
}
