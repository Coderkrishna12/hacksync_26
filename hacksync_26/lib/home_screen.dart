// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:hacksync_26/skills.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;
// import 'skills.dart'; // ← your SkillsWorkflow file
// import 'resume_preview_screen.dart'; // ← create this file as needed

// // --- MAIN HOME SCREEN WITH BOTTOM NAVIGATION (NOW 5 TABS) ---
// class HomeScreen extends StatefulWidget {
//   final int? initialTab;

//   const HomeScreen({super.key, this.initialTab});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   late int _selectedIndex;

//   @override
//   void initState() {
//     super.initState();
//     _selectedIndex = widget.initialTab ?? 0;
//   }

//   // List of screens (5 tabs now)
//   final List<Widget> _screens = const [
//     BytesFeedContent(), // 0
//     Center(child: Text("Bundles Screen", style: TextStyle(fontSize: 24))), // 1
//     Center(child: Text("Jobs Screen", style: TextStyle(fontSize: 24))), // 2
//     CareerRecommendationsScreen(), // 3 ← New career tab
//     ProfileScreen(), // 4
//   ];

//   final List<String> _titles = [
//     'Bytes',
//     'Bundles',
//     'Jobs',
//     'Recommendations',
//     'Profile',
//   ];

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: Text(
//           _titles[_selectedIndex],
//           style: const TextStyle(fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black87,
//         elevation: 0,
//       ),
//       body: _screens[_selectedIndex],
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         onTap: _onItemTapped,
//         type: BottomNavigationBarType.fixed,
//         selectedItemColor: const Color(0xFF2563EB),
//         unselectedItemColor: Colors.grey,
//         backgroundColor: Colors.white,
//         elevation: 10,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.play_arrow_rounded),
//             label: 'Bytes',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.playlist_play_rounded),
//             label: 'Bundles',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.work_rounded),
//             label: 'Jobs',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.trending_up_rounded),
//             label: 'Recommendations',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person_rounded),
//             label: 'Profile',
//           ),
//         ],
//       ),
//     );
//   }
// }

// // --- BYTES FEED COMPONENT (unchanged) ---
// class BytesFeedContent extends StatelessWidget {
//   const BytesFeedContent({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 24.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(
//               Icons.play_circle_fill_rounded,
//               size: 100,
//               color: Color(0xFF2563EB),
//             ),
//             const SizedBox(height: 24),
//             const Text(
//               "Bytes",
//               style: TextStyle(
//                 fontSize: 32,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF2563EB),
//               ),
//             ),
//             const Text(
//               "Short videos, quick insights",
//               style: TextStyle(fontSize: 16, color: Colors.grey),
//             ),
//             const SizedBox(height: 48),
//             const Text(
//               "Your feed will appear here soon...",
//               style: TextStyle(color: Colors.grey),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // --- NEW CAREER RECOMMENDATIONS TAB ---
// class CareerRecommendationsScreen extends StatefulWidget {
//   const CareerRecommendationsScreen({super.key});

//   @override
//   State<CareerRecommendationsScreen> createState() =>
//       _CareerRecommendationsScreenState();
// }

// class _CareerRecommendationsScreenState
//     extends State<CareerRecommendationsScreen> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   List<dynamic> _careers = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadRecommendations();
//   }

//   Future<void> _loadRecommendations() async {
//     setState(() => _isLoading = true);
//     final user = _auth.currentUser;
//     if (user == null) {
//       setState(() => _isLoading = false);
//       return;
//     }

//     try {
//       final doc = await _firestore
//           .collection('users')
//           .doc(user.uid)
//           .collection('career_recommendations')
//           .get();

//       if (doc.docs.isNotEmpty) {
//         _careers = doc.docs.map((e) => e.data()).toList();
//       }
//     } catch (e) {
//       debugPrint('Error loading recommendations: $e');
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     if (_careers.isEmpty) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.all(32),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Icons.lightbulb_outline_rounded,
//                 size: 100,
//                 color: Colors.grey[400],
//               ),
//               const SizedBox(height: 24),
//               const Text(
//                 'No career recommendations yet',
//                 style: TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.grey,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 12),
//               const Text(
//                 'Complete the quick setup to get personalized career matches',
//                 style: TextStyle(fontSize: 16, color: Colors.grey),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 40),
//               SizedBox(
//                 width: double.infinity,
//                 height: 56,
//                 child: ElevatedButton.icon(
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (_) => const SkillsWorkflow()),
//                     );
//                   },
//                   icon: const Icon(Icons.arrow_forward_rounded),
//                   label: const Text(
//                     'Get Career Recommendations',
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF2563EB),
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     return RefreshIndicator(
//       onRefresh: _loadRecommendations,
//       child: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: _careers.length,
//         itemBuilder: (context, i) {
//           final c = _careers[i];
//           return Card(
//             margin: const EdgeInsets.only(bottom: 20),
//             elevation: 3,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     c['career'] ?? 'Unknown Career',
//                     style: const TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     c['fit'] ?? '',
//                     style: TextStyle(
//                       color: Colors.green[700],
//                       fontWeight: FontWeight.w600,
//                       fontSize: 15,
//                     ),
//                   ),
//                   Text(
//                     '${c['score'] ?? 0}% Match',
//                     style: const TextStyle(
//                       fontSize: 16,
//                       color: Colors.blueGrey,
//                     ),
//                   ),
//                   const Divider(height: 24),
//                   Text('Industry: ${c['industry'] ?? '—'}'),
//                   Text('Trend Score: ${c['trend_score'] ?? '?'} / 10'),
//                   const SizedBox(height: 12),
//                   Text(
//                     'Matched Skills: ${c['matched_skills']?.join(', ') ?? 'None'}',
//                     style: const TextStyle(color: Colors.green),
//                   ),
//                   Text(
//                     'Missing Skills: ${c['missing_skills']?.join(', ') ?? 'None'}',
//                     style: const TextStyle(color: Colors.orange),
//                   ),
//                   const SizedBox(height: 12),
//                   Text(
//                     'Next Steps:\n${c['next_steps'] ?? '—'}',
//                     style: const TextStyle(fontSize: 14, height: 1.4),
//                   ),
//                   const SizedBox(height: 20),
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton.icon(
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => ResumePreviewScreen(career: c),
//                           ),
//                         );
//                       },
//                       icon: const Icon(Icons.description, size: 20),
//                       label: const Text('Build Resume for this Role'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF2563EB),
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// // --- THE PROFILE SCREEN COMPONENT ---
// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseStorage _storage = FirebaseStorage.instance;
//   final ImagePicker _picker = ImagePicker();

//   final TextEditingController _bioController = TextEditingController();
//   final TextEditingController _aboutController = TextEditingController();
//   final TextEditingController _workExpController = TextEditingController();
//   final TextEditingController _educationController = TextEditingController();

//   String _profilePicUrl = '';
//   List<String> _industrySkills = [];
//   List<String> _topSkills = [];
//   bool _isLoading = true;
//   bool _isSaving = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadProfileData();
//   }

//   Future<void> _loadProfileData() async {
//     final user = _auth.currentUser;
//     if (user == null) return;

//     try {
//       final skillsDoc = await _firestore
//           .collection('users')
//           .doc(user.uid)
//           .collection('skills')
//           .doc('profile_skills')
//           .get();
//       if (skillsDoc.exists) {
//         _industrySkills = List<String>.from(skillsDoc['industry_skills'] ?? []);
//         _topSkills = List<String>.from(skillsDoc['top_skills'] ?? []);
//       }

//       final profileDoc = await _firestore
//           .collection('users')
//           .doc(user.uid)
//           .collection('profile')
//           .doc('details')
//           .get();
//       if (profileDoc.exists) {
//         _bioController.text = profileDoc['bio'] ?? '';
//         _aboutController.text = profileDoc['about'] ?? '';
//         _workExpController.text = profileDoc['work_experience'] ?? '';
//         _educationController.text = profileDoc['education'] ?? '';
//         _profilePicUrl = profileDoc['profile_pic_url'] ?? '';
//       }
//     } catch (e) {
//       debugPrint("Error loading profile: $e");
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _uploadProfilePic() async {
//     final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//     if (image == null) return;
//     final user = _auth.currentUser;
//     if (user == null) return;

//     setState(() => _isSaving = true);
//     try {
//       final ref = _storage.ref('user_profiles/${user.uid}/profile_pic.jpg');
//       await ref.putFile(File(image.path));
//       final url = await ref.getDownloadURL();

//       await _firestore
//           .collection('users')
//           .doc(user.uid)
//           .collection('profile')
//           .doc('details')
//           .set({'profile_pic_url': url}, SetOptions(merge: true));

//       setState(() => _profilePicUrl = url);
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
//     } finally {
//       setState(() => _isSaving = false);
//     }
//   }

//   Future<void> _saveProfileDetails() async {
//     final user = _auth.currentUser;
//     if (user == null) return;

//     setState(() => _isSaving = true);
//     try {
//       await _firestore
//           .collection('users')
//           .doc(user.uid)
//           .collection('profile')
//           .doc('details')
//           .set({
//             'bio': _bioController.text,
//             'about': _aboutController.text,
//             'work_experience': _workExpController.text,
//             'education': _educationController.text,
//           }, SetOptions(merge: true));

//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Profile updated!")));
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Save failed: $e")));
//     } finally {
//       setState(() => _isSaving = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) return const Center(child: CircularProgressIndicator());

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(24.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Center(
//             child: Stack(
//               children: [
//                 CircleAvatar(
//                   radius: 60,
//                   backgroundColor: Colors.grey[200],
//                   backgroundImage: _profilePicUrl.isNotEmpty
//                       ? NetworkImage(_profilePicUrl)
//                       : null,
//                   child: _profilePicUrl.isEmpty
//                       ? const Icon(Icons.person, size: 80, color: Colors.grey)
//                       : null,
//                 ),
//                 Positioned(
//                   bottom: 0,
//                   right: 0,
//                   child: Container(
//                     decoration: const BoxDecoration(
//                       color: Color(0xFF2563EB),
//                       shape: BoxShape.circle,
//                     ),
//                     child: IconButton(
//                       icon: const Icon(
//                         Icons.camera_alt_rounded,
//                         color: Colors.white,
//                         size: 20,
//                       ),
//                       onPressed: _isSaving ? null : _uploadProfilePic,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 32),
//           _buildFieldTitle("Bio"),
//           TextField(
//             controller: _bioController,
//             decoration: const InputDecoration(
//               hintText: "Short bio",
//               border: OutlineInputBorder(),
//             ),
//             maxLines: 2,
//           ),
//           const SizedBox(height: 24),
//           _buildFieldTitle("About"),
//           TextField(
//             controller: _aboutController,
//             decoration: const InputDecoration(
//               hintText: "Tell us about yourself",
//               border: OutlineInputBorder(),
//             ),
//             maxLines: 4,
//           ),
//           const SizedBox(height: 24),
//           _buildFieldTitle("Industry Skills"),
//           Wrap(
//             spacing: 8,
//             children: _industrySkills.map((s) => Chip(label: Text(s))).toList(),
//           ),
//           const SizedBox(height: 24),
//           _buildFieldTitle("Work Experience"),
//           TextField(
//             controller: _workExpController,
//             decoration: const InputDecoration(border: OutlineInputBorder()),
//             maxLines: 3,
//           ),
//           const SizedBox(height: 32),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: _isSaving ? null : _saveProfileDetails,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF2563EB),
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//               ),
//               child: _isSaving
//                   ? const CircularProgressIndicator(color: Colors.white)
//                   : const Text("Save Profile"),
//             ),
//           ),
//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }

//   Widget _buildFieldTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8.0),
//       child: Text(
//         title,
//         style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _bioController.dispose();
//     _aboutController.dispose();
//     _workExpController.dispose();
//     _educationController.dispose();
//     super.dispose();
//   }
// }

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:hacksync_26/job_search.dart';
import 'package:hacksync_26/profile_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

// ── MAIN HOME SCREEN ───────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isSaving = false;

  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return const BytesFeedContent();
      case 1:
        return const BundlesScreen();
      case 2:
        return const JobsSection();
      case 3:
        return const ProfileScreen();
      default:
        return const BytesFeedContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          ['Bytes', 'Bundles', 'Jobs', 'Profile'][_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _buildCurrentScreen(),
      floatingActionButton: _selectedIndex == 0 || _selectedIndex == 1
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF0A66C2),
              onPressed: () {
                if (_selectedIndex == 0) _createByteWithVideo(context);
                if (_selectedIndex == 1) _createBundle(context);
              },
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0A66C2),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.play_arrow_rounded),
            label: 'Bytes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.playlist_play_rounded),
            label: 'Bundles',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_rounded),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Future<void> _createByteWithVideo(BuildContext context) async {
    final picker = ImagePicker();

    // Pick video from gallery (you can add camera support later)
    final XFile? videoFile = await picker.pickVideo(
      source: ImageSource.gallery,
    );

    if (videoFile == null) return;

    final titleController = TextEditingController();
    final hashtagsController = TextEditingController();

    // Optional: Get video duration
    String durationStr = "Unknown";
    try {
      final controller = VideoPlayerController.file(File(videoFile.path));
      await controller.initialize();
      final duration = controller.value.duration;
      durationStr =
          "${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
      controller.dispose();
    } catch (e) {
      // Fallback if duration can't be read
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 24,
          right: 24,
          top: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Create New Byte",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              "Selected video: ${videoFile.name}",
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              "Duration: $durationStr",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Byte Title",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: hashtagsController,
              decoration: InputDecoration(
                labelText: "Hashtags (comma separated)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                hintText: "e.g. python, coding, flutter",
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A66C2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final title = titleController.text.trim();
                  final hashtagsText = hashtagsController.text.trim();

                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Title is required")),
                    );
                    return;
                  }

                  final uid = FirebaseAuth.instance.currentUser!.uid;

                  try {
                    setState(() => _isSaving = true); // If you have this state

                    // 1. Upload video to Storage
                    final videoRef = FirebaseStorage.instance.ref(
                      'user_bytes/$uid/${DateTime.now().millisecondsSinceEpoch}.mp4',
                    );
                    await videoRef.putFile(File(videoFile.path));
                    final videoUrl = await videoRef.getDownloadURL();

                    // 2. Save metadata to Firestore
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('bytes')
                        .add({
                          'title': title,
                          'hashtags': hashtagsText
                              .split(',')
                              .map((e) => e.trim().toLowerCase())
                              .where((e) => e.isNotEmpty)
                              .toList(),
                          'videoUrl': videoUrl,
                          'duration': durationStr,
                          'createdAt': FieldValue.serverTimestamp(),
                          'userId': uid,
                        });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Byte video uploaded successfully!"),
                      ),
                    );

                    Navigator.pop(context);

                    // Optional: Refresh profile bytes list if you're in profile
                    if (_selectedIndex == 3) {
                      // Call _loadProfile() or similar
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Upload failed: $e")),
                    );
                  } finally {
                    setState(() => _isSaving = false);
                  }
                },
                child: const Text(
                  "Upload & Create Byte",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── CREATE BUNDLE ─────────────────────────────────────────────────────────
  Future<void> _createBundle(BuildContext context) async {
    final nameController = TextEditingController();
    XFile? thumbnailImage;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 24,
            right: 24,
            top: 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Create New Bundle",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Bundle Name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () async {
                  final picked = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                  );
                  if (picked != null) {
                    setModalState(() => thumbnailImage = picked);
                  }
                },
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade100,
                  ),
                  child: thumbnailImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Tap to add thumbnail",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(thumbnailImage!.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A66C2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty || thumbnailImage == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Name and thumbnail are required"),
                        ),
                      );
                      return;
                    }

                    final uid = FirebaseAuth.instance.currentUser!.uid;

                    try {
                      // Upload thumbnail
                      final ref = FirebaseStorage.instance.ref(
                        'bundles_thumbnails/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg',
                      );
                      await ref.putFile(File(thumbnailImage!.path));
                      final thumbnailUrl = await ref.getDownloadURL();

                      // Create bundle document
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('bundles')
                          .add({
                            'name': name,
                            'thumbnailUrl': thumbnailUrl,
                            'createdAt': FieldValue.serverTimestamp(),
                            'byteIds': [], // You can later allow adding bytes
                            'userId': uid,
                          });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Bundle created successfully!"),
                        ),
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to create bundle: $e")),
                      );
                    }
                  },
                  child: const Text(
                    "Create Bundle",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── BYTES FEED (unchanged) ─────────────────────────────────────────────────
class BytesFeedContent extends StatefulWidget {
  const BytesFeedContent({super.key});

  @override
  State<BytesFeedContent> createState() => _BytesFeedContentState();
}

class _BytesFeedContentState extends State<BytesFeedContent> {
  final List<Map<String, dynamic>> _bytes = [
    {
      'title': 'What is Compound Interest Really?',
      'description': '₹10,000 at 12% per year — see how it grows!',
      'duration': '38s',
      'color': Colors.blue[700],
      'icon': Icons.trending_up_rounded,
    },
    {
      'title': 'Most Asked SQL Interview Question',
      'description': 'Find 2nd highest salary in one clean query',
      'duration': '52s',
      'color': Colors.purple[600],
      'icon': Icons.code_rounded,
    },
    {
      'title': 'Git Rebase vs Merge Explained',
      'description': 'When to use which — 45 second crash course',
      'duration': '45s',
      'color': Colors.teal[700],
      'icon': Icons.merge_type_rounded,
    },
    {
      'title': 'How DNS Actually Works',
      'description': 'Browser → IP in milliseconds',
      'duration': '1:02',
      'color': Colors.deepOrange[600],
      'icon': Icons.language_rounded,
    },
    {
      'title': 'Big-O Notation in 60 Seconds',
      'description': 'O(1) → O(n) → O(n²) visual breakdown',
      'duration': '58s',
      'color': Colors.indigo[700],
      'icon': Icons.speed_rounded,
    },
    {
      'title': 'Why const in Flutter matters',
      'description': 'The performance difference is huge!',
      'duration': '42s',
      'color': Colors.green[700],
      'icon': Icons.code_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: _bytes.length,
      itemBuilder: (context, index) {
        final byte = _bytes[index];
        return _ByteCard(byte: byte, index: index);
      },
    );
  }
}

class _ByteCard extends StatelessWidget {
  final Map<String, dynamic> byte;
  final int index;

  const _ByteCard({required this.byte, required this.index});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = byte['color'] as Color;

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                backgroundColor.withOpacity(0.92),
                backgroundColor.withOpacity(0.72),
                Colors.black.withOpacity(0.94),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    byte['icon'],
                    size: 80,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  byte['title'],
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  byte['description'],
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.white.withOpacity(0.86),
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        byte['duration'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.24),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        Positioned(
          right: 20,
          bottom: 140,
          child: Column(
            children: [
              _buildActionButton(
                Icons.favorite_border_rounded,
                '${(index * 23 + 7) * 10}+',
              ),
              const SizedBox(height: 40),
              _buildActionButton(Icons.comment_outlined, '${index * 4 + 2}'),
              const SizedBox(height: 40),
              _buildActionButton(Icons.share_rounded, ''),
            ],
          ),
        ),
        if (index == 0)
          Positioned(
            bottom: 90,
            left: 0,
            right: 0,
            child: Column(
              children: const [
                Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: Colors.white70,
                  size: 48,
                ),
                SizedBox(height: 8),
                Text(
                  "Swipe up for more bytes",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ],
    );
  }
}

// ── BUNDLES SCREEN (placeholder for now) ───────────────────────────────────
class BundlesScreen extends StatelessWidget {
  const BundlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Bundles Screen\n(Create and discover bundles)",
        style: TextStyle(fontSize: 24),
        textAlign: TextAlign.center,
      ),
    );
  }
}
