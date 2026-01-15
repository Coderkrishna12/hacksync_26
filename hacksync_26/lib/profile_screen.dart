import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

  // Controllers for editable fields
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _workExpController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();

  // State variables
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
    if (user == null) {
      // Handle not logged in (though unlikely here)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please sign in to view profile")),
      );
      return;
    }

    try {
      // Fetch skills from existing path
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

      // Fetch profile data (new path: users/{uid}/profile)
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading profile: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadProfilePic() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      // Upload to Storage
      final ref = _storage.ref('user_profiles/${user.uid}/profile_pic.jpg');
      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();

      // Save URL to Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('details')
          .set({'profile_pic_url': url}, SetOptions(merge: true));

      setState(() => _profilePicUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile picture updated!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading picture: $e")),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile details saved!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving details: $e")),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Pic Upload
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _profilePicUrl.isNotEmpty
                              ? NetworkImage(_profilePicUrl)
                              : null,
                          child: _profilePicUrl.isEmpty
                              ? const Icon(Icons.person, size: 80)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt_rounded),
                            onPressed: _isSaving ? null : _uploadProfilePic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bio
                  const Text(
                    "Bio",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                      hintText: "Enter your bio...",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // About
                  const Text(
                    "About",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _aboutController,
                    decoration: const InputDecoration(
                      hintText: "Tell us about yourself...",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 24),

                  // Selected Industry Skills
                  const Text(
                    "Industry Skills",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _industrySkills.map((skill) => Chip(label: Text(skill))).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Top Skills
                  const Text(
                    "Top Skills",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _topSkills.map((skill) => Chip(label: Text(skill))).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Work Experience
                  const Text(
                    "Work Experience",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _workExpController,
                    decoration: const InputDecoration(
                      hintText: "Add your work experience...",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),

                  // Education
                  const Text(
                    "Education",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _educationController,
                    decoration: const InputDecoration(
                      hintText: "Add your education details...",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfileDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Save Profile", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
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