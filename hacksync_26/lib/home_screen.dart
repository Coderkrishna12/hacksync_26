import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hacksync_26/skills.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'skills.dart'; // ← your SkillsWorkflow file
import 'resume_preview_screen.dart'; // ← create this file as needed

// --- MAIN HOME SCREEN WITH BOTTOM NAVIGATION (NOW 5 TABS) ---
class HomeScreen extends StatefulWidget {
  final int? initialTab;

  const HomeScreen({super.key, this.initialTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab ?? 0;
  }

  // List of screens (5 tabs now)
  final List<Widget> _screens = const [
    BytesFeedContent(), // 0
    Center(child: Text("Bundles Screen", style: TextStyle(fontSize: 24))), // 1
    Center(child: Text("Jobs Screen", style: TextStyle(fontSize: 24))), // 2
    CareerRecommendationsScreen(), // 3 ← New career tab
    ProfileScreen(), // 4
  ];

  final List<String> _titles = [
    'Bytes',
    'Bundles',
    'Jobs',
    'Recommendations',
    'Profile',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2563EB),
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
            icon: Icon(Icons.trending_up_rounded),
            label: 'Recommendations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// --- BYTES FEED COMPONENT (unchanged) ---
class BytesFeedContent extends StatelessWidget {
  const BytesFeedContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.play_circle_fill_rounded,
              size: 100,
              color: Color(0xFF2563EB),
            ),
            const SizedBox(height: 24),
            const Text(
              "Bytes",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              ),
            ),
            const Text(
              "Short videos, quick insights",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 48),
            const Text(
              "Your feed will appear here soon...",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// --- NEW CAREER RECOMMENDATIONS TAB ---
class CareerRecommendationsScreen extends StatefulWidget {
  const CareerRecommendationsScreen({super.key});

  @override
  State<CareerRecommendationsScreen> createState() =>
      _CareerRecommendationsScreenState();
}

class _CareerRecommendationsScreenState
    extends State<CareerRecommendationsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<dynamic> _careers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('career_recommendations')
          .get();

      if (doc.docs.isNotEmpty) {
        _careers = doc.docs.map((e) => e.data()).toList();
      }
    } catch (e) {
      debugPrint('Error loading recommendations: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_careers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 100,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              const Text(
                'No career recommendations yet',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Complete the quick setup to get personalized career matches',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SkillsWorkflow()),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text(
                    'Get Career Recommendations',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecommendations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _careers.length,
        itemBuilder: (context, i) {
          final c = _careers[i];
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
                            builder: (_) => ResumePreviewScreen(career: c),
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
    );
  }
}

// --- THE PROFILE SCREEN COMPONENT ---
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _workExpController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();

  String _profilePicUrl = '';
  List<String> _industrySkills = [];
  List<String> _topSkills = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final skillsDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('skills')
          .doc('profile_skills')
          .get();
      if (skillsDoc.exists) {
        _industrySkills = List<String>.from(skillsDoc['industry_skills'] ?? []);
        _topSkills = List<String>.from(skillsDoc['top_skills'] ?? []);
      }

      final profileDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('details')
          .get();
      if (profileDoc.exists) {
        _bioController.text = profileDoc['bio'] ?? '';
        _aboutController.text = profileDoc['about'] ?? '';
        _workExpController.text = profileDoc['work_experience'] ?? '';
        _educationController.text = profileDoc['education'] ?? '';
        _profilePicUrl = profileDoc['profile_pic_url'] ?? '';
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadProfilePic() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final ref = _storage.ref('user_profiles/${user.uid}/profile_pic.jpg');
      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('details')
          .set({'profile_pic_url': url}, SetOptions(merge: true));

      setState(() => _profilePicUrl = url);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _saveProfileDetails() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('details')
          .set({
            'bio': _bioController.text,
            'about': _aboutController.text,
            'work_experience': _workExpController.text,
            'education': _educationController.text,
          }, SetOptions(merge: true));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profile updated!")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Save failed: $e")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _profilePicUrl.isNotEmpty
                      ? NetworkImage(_profilePicUrl)
                      : null,
                  child: _profilePicUrl.isEmpty
                      ? const Icon(Icons.person, size: 80, color: Colors.grey)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _isSaving ? null : _uploadProfilePic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildFieldTitle("Bio"),
          TextField(
            controller: _bioController,
            decoration: const InputDecoration(
              hintText: "Short bio",
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          _buildFieldTitle("About"),
          TextField(
            controller: _aboutController,
            decoration: const InputDecoration(
              hintText: "Tell us about yourself",
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          _buildFieldTitle("Industry Skills"),
          Wrap(
            spacing: 8,
            children: _industrySkills.map((s) => Chip(label: Text(s))).toList(),
          ),
          const SizedBox(height: 24),
          _buildFieldTitle("Work Experience"),
          TextField(
            controller: _workExpController,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            maxLines: 3,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfileDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Save Profile"),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFieldTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  void dispose() {
    _bioController.dispose();
    _aboutController.dispose();
    _workExpController.dispose();
    _educationController.dispose();
    super.dispose();
  }
}
