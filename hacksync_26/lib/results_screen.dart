// import 'package:flutter/material.dart';
// import 'resume_preview_screen.dart'; // adjust path

// class ResultsScreen extends StatelessWidget {
//   final List<dynamic> careers;
//   final VoidCallback? onUpdatePreferences;

//   const ResultsScreen({
//     super.key,
//     required this.careers,
//     this.onUpdatePreferences,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Career Recommendations'),
//         backgroundColor: const Color(0xFF2563EB),
//         foregroundColor: Colors.white,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           if (onUpdatePreferences != null)
//             IconButton(
//               icon: const Icon(Icons.edit),
//               tooltip: 'Change preferences',
//               onPressed: onUpdatePreferences,
//             ),
//         ],
//       ),
//       body: careers.isEmpty
//           ? const Center(
//               child: Text(
//                 'No strong matches found.\nTry updating your preferences!',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 18, color: Colors.grey),
//               ),
//             )
//           : ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: careers.length,
//               itemBuilder: (context, i) {
//                 final c = careers[i];
//                 return Card(
//                   margin: const EdgeInsets.only(bottom: 20),
//                   elevation: 3,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(20),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           c['career'] ?? 'Unknown Career',
//                           style: const TextStyle(
//                             fontSize: 22,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 6),
//                         Text(
//                           c['fit'] ?? '',
//                           style: TextStyle(
//                             color: Colors.green[700],
//                             fontWeight: FontWeight.w600,
//                             fontSize: 15,
//                           ),
//                         ),
//                         Text(
//                           '${c['score'] ?? 0}% Match',
//                           style: const TextStyle(
//                             fontSize: 16,
//                             color: Colors.blueGrey,
//                           ),
//                         ),
//                         const Divider(height: 24),
//                         Text('Industry: ${c['industry'] ?? '—'}'),
//                         Text('Trend Score: ${c['trend_score'] ?? '?'} / 10'),
//                         const SizedBox(height: 12),
//                         Text(
//                           'Matched Skills: ${c['matched_skills']?.join(', ') ?? 'None'}',
//                           style: const TextStyle(color: Colors.green),
//                         ),
//                         Text(
//                           'Missing Skills: ${c['missing_skills']?.join(', ') ?? 'None'}',
//                           style: const TextStyle(color: Colors.orange),
//                         ),
//                         const SizedBox(height: 12),
//                         Text(
//                           'Next Steps:\n${c['next_steps'] ?? '—'}',
//                           style: const TextStyle(fontSize: 14, height: 1.4),
//                         ),
//                         const SizedBox(height: 20),
//                         SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton.icon(
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (_) =>
//                                       ResumePreviewScreen(career: c),
//                                 ),
//                               );
//                             },
//                             icon: const Icon(Icons.description, size: 20),
//                             label: const Text('Build Resume for this Role'),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: const Color(0xFF2563EB),
//                               foregroundColor: Colors.white,
//                               padding: const EdgeInsets.symmetric(vertical: 14),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }

// main_navigation.dart  (updated)
import 'package:flutter/material.dart';
import 'resume_preview_screen.dart'; // adjust path

// Import the screens that already exist in your MainNavigation
import 'home_screen.dart'; // or whatever contains BytesFeedContent
import 'bundles_screen.dart';
import 'job_search.dart';
import 'profile_screen.dart';
import 'skills.dart'; // SkillsWorkflow = Career tab

class ResultsScreen extends StatefulWidget {
  final List<dynamic> careers;
  final VoidCallback? onUpdatePreferences;

  const ResultsScreen({
    super.key,
    required this.careers,
    this.onUpdatePreferences,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  int _currentIndex = 4; // Start on Career tab (index 4)

  // Same titles & items as MainNavigation
  static const List<String> _titles = [
    "Bytes",
    "Bundles",
    "Jobs",
    "Profile",
    "Career",
  ];

  void _onTap(int index) {
    if (index == _currentIndex) return;

    // Pop back to root when switching tabs (common pattern)
    Navigator.popUntil(context, (route) => route.isFirst);

    // Then let MainNavigation handle the tab change
    // (Alternative: use a global key / provider to change tab index)
    // For simplicity we just pop — user can tap Career again if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Recommendations'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.onUpdatePreferences != null)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Change preferences',
              onPressed: widget.onUpdatePreferences,
            ),
        ],
      ),

      // ← The body remains almost the same
      body: widget.careers.isEmpty
          ? const Center(
              child: Text(
                'No strong matches found.\nTry updating your preferences!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.careers.length,
              itemBuilder: (context, i) {
                final c = widget.careers[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c['career'] ?? 'Unknown Career',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          c['fit'] ?? '',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${c['score'] ?? 0}% Match',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const Divider(height: 24),
                        Text('Industry: ${c['industry'] ?? '—'}'),
                        Text('Trend Score: ${c['trend_score'] ?? '?'} / 10'),
                        const SizedBox(height: 12),
                        Text(
                          'Matched Skills: ${c['matched_skills']?.join(', ') ?? 'None'}',
                          style: const TextStyle(color: Colors.green),
                        ),
                        Text(
                          'Missing Skills: ${c['missing_skills']?.join(', ') ?? 'None'}',
                          style: const TextStyle(color: Colors.orange),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Next Steps:\n${c['next_steps'] ?? '—'}',
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ResumePreviewScreen(career: c),
                                ),
                              );
                            },
                            icon: const Icon(Icons.description, size: 20),
                            label: const Text('Build Resume for this Role'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

      // ── Bottom Navigation Bar added here ────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        onTap: _onTap,
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
