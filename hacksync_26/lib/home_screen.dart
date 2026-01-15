import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

// --- MAIN HOME SCREEN WITH BOTTOM NAVIGATION ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // List of widgets to display based on the selected index
  final List<Widget> _screens = [
    const BytesFeedContent(),    // Index 0
    const Center(child: Text("Bundles Screen", style: TextStyle(fontSize: 24))), // Index 1
    const Center(child: Text("Jobs Screen", style: TextStyle(fontSize: 24))),    // Index 2
    const ProfileScreen(),      // Index 3 (Your integrated Profile Screen)
  ];

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
      // This is where the magic happens: only the body changes, 
      // the Scaffold (and thus the BottomNavBar) stays the same.
      body: _screens[_selectedIndex],
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.play_arrow_rounded), label: 'Bytes'),
          BottomNavigationBarItem(icon: Icon(Icons.playlist_play_rounded), label: 'Bundles'),
          BottomNavigationBarItem(icon: Icon(Icons.work_rounded), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

// --- BYTES FEED COMPONENT ---
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
            const Icon(Icons.play_circle_fill_rounded, size: 100, color: Color(0xFF2563EB)),
            const SizedBox(height: 24),
            const Text("Bytes", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
            const Text("Short videos, quick insights", style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 48),
            const Text("Your feed will appear here soon...", style: TextStyle(color: Colors.grey)),
          ],
        ),
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
      final skillsDoc = await _firestore.collection('users').doc(user.uid).collection('skills').doc('profile_skills').get();
      if (skillsDoc.exists) {
        _industrySkills = List<String>.from(skillsDoc['industry_skills'] ?? []);
        _topSkills = List<String>.from(skillsDoc['top_skills'] ?? []);
      }

      final profileDoc = await _firestore.collection('users').doc(user.uid).collection('profile').doc('details').get();
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

      await _firestore.collection('users').doc(user.uid).collection('profile').doc('details').set(
        {'profile_pic_url': url}, SetOptions(merge: true)
      );

      setState(() => _profilePicUrl = url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _saveProfileDetails() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      await _firestore.collection('users').doc(user.uid).collection('profile').doc('details').set({
        'bio': _bioController.text,
        'about': _aboutController.text,
        'work_experience': _workExpController.text,
        'education': _educationController.text,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Save failed: $e")));
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
                  backgroundImage: _profilePicUrl.isNotEmpty ? NetworkImage(_profilePicUrl) : null,
                  child: _profilePicUrl.isEmpty ? const Icon(Icons.person, size: 80, color: Colors.grey) : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                      onPressed: _isSaving ? null : _uploadProfilePic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildFieldTitle("Bio"),
          TextField(controller: _bioController, decoration: const InputDecoration(hintText: "Short bio", border: OutlineInputBorder()), maxLines: 2),
          const SizedBox(height: 24),
          _buildFieldTitle("About"),
          TextField(controller: _aboutController, decoration: const InputDecoration(hintText: "Tell us about yourself", border: OutlineInputBorder()), maxLines: 4),
          const SizedBox(height: 24),
          _buildFieldTitle("Industry Skills"),
          Wrap(spacing: 8, children: _industrySkills.map((s) => Chip(label: Text(s))).toList()),
          const SizedBox(height: 24),
          _buildFieldTitle("Work Experience"),
          TextField(controller: _workExpController, decoration: const InputDecoration(border: OutlineInputBorder()), maxLines: 3),
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
              child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("Save Profile"),
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
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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