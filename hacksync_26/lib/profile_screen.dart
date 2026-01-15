// import 'dart:io';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';

// import 'signin.dart'; // ← Import your SignIn screen here

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

//   // Controllers for editable fields
//   final TextEditingController _bioController = TextEditingController();
//   final TextEditingController _aboutController = TextEditingController();
//   final TextEditingController _workExpController = TextEditingController();
//   final TextEditingController _educationController = TextEditingController();

//   // State variables
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
//     if (user == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please sign in to view profile")),
//       );
//       return;
//     }

//     try {
//       // Fetch skills
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

//       // Fetch profile data
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
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Error loading profile: $e")));
//     } finally {
//       setState(() => _isLoading = false);
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
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Profile picture updated!")));
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Error uploading picture: $e")));
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
//       ).showSnackBar(const SnackBar(content: Text("Profile details saved!")));
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Error saving details: $e")));
//     } finally {
//       setState(() => _isSaving = false);
//     }
//   }

//   Future<void> _logout() async {
//     try {
//       await _auth.signOut();
//       // Navigate to SignIn screen and remove all previous routes
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(builder: (context) => const LoginPage()),
//         (route) => false,
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Error signing out: $e")));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Profile"), centerTitle: true),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(24.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Profile Pic Upload
//                   Center(
//                     child: Stack(
//                       children: [
//                         CircleAvatar(
//                           radius: 60,
//                           backgroundImage: _profilePicUrl.isNotEmpty
//                               ? NetworkImage(_profilePicUrl)
//                               : null,
//                           child: _profilePicUrl.isEmpty
//                               ? const Icon(Icons.person, size: 80)
//                               : null,
//                         ),
//                         Positioned(
//                           bottom: 0,
//                           right: 0,
//                           child: IconButton(
//                             icon: const Icon(Icons.camera_alt_rounded),
//                             onPressed: _isSaving ? null : _uploadProfilePic,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 32),

//                   // Bio
//                   const Text(
//                     "Bio",
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 8),
//                   TextField(
//                     controller: _bioController,
//                     decoration: const InputDecoration(
//                       hintText: "Enter your bio...",
//                       border: OutlineInputBorder(),
//                     ),
//                     maxLines: 2,
//                   ),
//                   const SizedBox(height: 24),

//                   // About
//                   const Text(
//                     "About",
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 8),
//                   TextField(
//                     controller: _aboutController,
//                     decoration: const InputDecoration(
//                       hintText: "Tell us about yourself...",
//                       border: OutlineInputBorder(),
//                     ),
//                     maxLines: 5,
//                   ),
//                   const SizedBox(height: 24),

//                   // Industry Skills
//                   const Text(
//                     "Industry Skills",
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 8),
//                   Wrap(
//                     spacing: 8,
//                     runSpacing: 8,
//                     children: _industrySkills
//                         .map((skill) => Chip(label: Text(skill)))
//                         .toList(),
//                   ),
//                   const SizedBox(height: 24),

//                   // Top Skills
//                   const Text(
//                     "Top Skills",
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 8),
//                   Wrap(
//                     spacing: 8,
//                     runSpacing: 8,
//                     children: _topSkills
//                         .map((skill) => Chip(label: Text(skill)))
//                         .toList(),
//                   ),
//                   const SizedBox(height: 24),

//                   // Work Experience
//                   const Text(
//                     "Work Experience",
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 8),
//                   TextField(
//                     controller: _workExpController,
//                     decoration: const InputDecoration(
//                       hintText: "Add your work experience...",
//                       border: OutlineInputBorder(),
//                     ),
//                     maxLines: 4,
//                   ),
//                   const SizedBox(height: 24),

//                   // Education
//                   const Text(
//                     "Education",
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 8),
//                   TextField(
//                     controller: _educationController,
//                     decoration: const InputDecoration(
//                       hintText: "Add your education details...",
//                       border: OutlineInputBorder(),
//                     ),
//                     maxLines: 4,
//                   ),
//                   const SizedBox(height: 32),

//                   // Save Button
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: _isSaving ? null : _saveProfileDetails,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF2563EB),
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                       ),
//                       child: _isSaving
//                           ? const CircularProgressIndicator(color: Colors.white)
//                           : const Text(
//                               "Save Profile",
//                               style: TextStyle(fontSize: 16),
//                             ),
//                     ),
//                   ),

//                   const SizedBox(height: 24),

//                   // Logout Button
//                   SizedBox(
//                     width: double.infinity,
//                     child: OutlinedButton.icon(
//                       onPressed: _logout,
//                       icon: const Icon(Icons.logout, color: Colors.red),
//                       label: const Text(
//                         "Logout",
//                         style: TextStyle(
//                           color: Colors.red,
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       style: OutlinedButton.styleFrom(
//                         side: const BorderSide(color: Colors.red, width: 2),
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
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
import 'package:image_picker/image_picker.dart'; // ── PROFILE SCREEN - Now shows user's Bytes & Bundles ──────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  String _profilePicUrl = '';
  String _coverPhotoUrl = '';
  String _fullName = 'User Name';
  String _headline = '';
  String _location = '';
  String _about = '';
  List<Map<String, dynamic>> education = [];
  List<Map<String, dynamic>> experience = [];
  List<String> skills = [];
  List<Map<String, dynamic>> userBytes = [];
  List<Map<String, dynamic>> userBundles = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final profileDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('profile')
          .doc('details')
          .get();

      final eduSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('profile')
          .doc('education')
          .collection('items')
          .orderBy('startDate', descending: true)
          .get();

      final expSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('profile')
          .doc('experience')
          .collection('items')
          .orderBy('startDate', descending: true)
          .get();

      final skillsDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('skills')
          .doc('profile_skills')
          .get();

      final bytesSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('bytes')
          .orderBy('createdAt', descending: true)
          .get();

      final bundlesSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('bundles')
          .orderBy('createdAt', descending: true)
          .get();

      if (!mounted) return;

      setState(() {
        _profilePicUrl = profileDoc.data()?['profile_pic_url'] ?? '';
        _coverPhotoUrl = profileDoc.data()?['cover_photo_url'] ?? '';
        _fullName = profileDoc.data()?['fullName'] ?? 'User Name';
        _headline = profileDoc.data()?['headline'] ?? '';
        _location = profileDoc.data()?['location'] ?? '';
        _about = profileDoc.data()?['about'] ?? '';

        education = eduSnap.docs.map((e) => {...e.data(), 'id': e.id}).toList();
        experience = expSnap.docs
            .map((e) => {...e.data(), 'id': e.id})
            .toList();
        skills = List<String>.from([
          ...?skillsDoc.data()?['top_skills'],
          ...?skillsDoc.data()?['other_skills'],
        ]).whereType<String>().toList();

        userBytes = bytesSnap.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
        userBundles = bundlesSnap.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error loading profile: $e")));
      }
    }
  }

  Future<void> _uploadImage(bool isProfilePic) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);

    try {
      final refPath = isProfilePic
          ? 'user_profiles/$uid/profile_pic.jpg'
          : 'user_profiles/$uid/cover_photo.jpg';
      final ref = _storage.ref(refPath);
      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();

      final field = isProfilePic ? 'profile_pic_url' : 'cover_photo_url';

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('profile')
          .doc('details')
          .set({field: url}, SetOptions(merge: true));

      setState(() {
        if (isProfilePic)
          _profilePicUrl = url;
        else
          _coverPhotoUrl = url;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Photo updated successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _editField({
    required String title,
    required String initialValue,
    required String fieldName,
    int maxLines = 1,
  }) async {
    final controller = TextEditingController(text: initialValue);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit $title"),
        content: TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: "Enter $title",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final trimmed = controller.text.trim();
              Navigator.pop(context, trimmed.isNotEmpty ? trimmed : null);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A66C2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Save"),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );

    if (result != null && result != initialValue) {
      setState(() => _isSaving = true);

      try {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('profile')
            .doc('details')
            .set({fieldName: result}, SetOptions(merge: true));

        setState(() {
          switch (fieldName) {
            case 'fullName':
              _fullName = result;
              break;
            case 'headline':
              _headline = result;
              break;
            case 'location':
              _location = result;
              break;
            case 'about':
              _about = result;
              break;
          }
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Updated successfully!")));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Update failed: $e")));
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _editProfile() async {
    final fullNameController = TextEditingController(text: _fullName);
    final headlineController = TextEditingController(text: _headline);
    final locationController = TextEditingController(text: _location);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profile"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fullNameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: headlineController,
                decoration: const InputDecoration(
                  labelText: "Headline",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: "Location",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              setState(() => _isSaving = true);

              try {
                await _firestore
                    .collection('users')
                    .doc(_auth.currentUser!.uid)
                    .collection('profile')
                    .doc('details')
                    .set({
                      'fullName': fullNameController.text.trim(),
                      'headline': headlineController.text.trim(),
                      'location': locationController.text.trim(),
                    }, SetOptions(merge: true));

                setState(() {
                  _fullName = fullNameController.text.trim();
                  _headline = headlineController.text.trim();
                  _location = locationController.text.trim();
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Profile updated successfully!"),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Update failed: $e")));
              } finally {
                setState(() => _isSaving = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A66C2),
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _addOrEditExperience(Map<String, dynamic>? exp) async {
    final isEdit = exp != null;

    final titleController = TextEditingController(
      text: exp?['title'] as String? ?? '',
    );
    final companyController = TextEditingController(
      text: exp?['company'] as String? ?? '',
    );

    DateTime? startDate = exp != null && exp['startDate'] is Timestamp
        ? (exp['startDate'] as Timestamp).toDate()
        : null;

    DateTime? endDate = exp != null && exp['endDate'] is Timestamp
        ? (exp['endDate'] as Timestamp).toDate()
        : null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? "Edit Experience" : "Add Experience"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Job Title",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: companyController,
                decoration: const InputDecoration(
                  labelText: "Company / Organization",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(1980),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null && mounted) {
                          setState(() => startDate = picked);
                        }
                      },
                      child: Text(
                        startDate == null
                            ? "Start Date"
                            : "Start: ${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}",
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? DateTime.now(),
                          firstDate: DateTime(1980),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null && mounted) {
                          setState(() => endDate = picked);
                        }
                      },
                      child: Text(
                        endDate == null
                            ? "End Date (or Present)"
                            : "End: ${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}",
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A66C2),
            ),
            child: Text(isEdit ? "Update" : "Add"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);

    try {
      final uid = _auth.currentUser!.uid;
      final data = {
        'title': titleController.text.trim(),
        'company': companyController.text.trim(),
        if (startDate != null) 'startDate': Timestamp.fromDate(startDate!),
        if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      };

      final collectionRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('profile')
          .doc('experience')
          .collection('items');

      if (isEdit && exp?['id'] != null) {
        await collectionRef.doc(exp!['id']).set(data, SetOptions(merge: true));
      } else {
        await collectionRef.add(data);
      }

      await _loadProfile();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? "Experience updated!" : "Experience added!"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed: $e")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ── SIGN OUT FUNCTION ──────────────────────────────────────────────────────
  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Signed out successfully")));
      // Optional: Navigate to login screen or restart app
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Sign out failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverToBoxAdapter(child: _buildInfoSection()),
        SliverToBoxAdapter(child: _buildAboutSection()),

        // User's Bytes Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: const Text(
              "Your Bytes",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final byte = userBytes[index];
            return ListTile(
              title: Text(byte['title'] ?? 'Untitled Byte'),
              subtitle: Text(byte['hashtags']?.join(', ') ?? 'No hashtags'),
              trailing: Text(
                byte['createdAt'] != null
                    ? (byte['createdAt'] as Timestamp)
                          .toDate()
                          .toString()
                          .split(' ')[0]
                    : '',
              ),
            );
          }, childCount: userBytes.length),
        ),

        // User's Bundles Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
            child: const Text(
              "Your Bundles",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final bundle = userBundles[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          BundleDetailScreen(bundleId: bundle['id']),
                    ),
                  );
                },
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      bundle['thumbnailUrl'] != null
                          ? Image.network(
                              bundle['thumbnailUrl'],
                              fit: BoxFit.cover,
                            )
                          : Container(color: Colors.grey.shade300),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                          child: Text(
                            bundle['name'] ?? 'Unnamed Bundle',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }, childCount: userBundles.length),
          ),
        ),

        // Sign Out Button Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ElevatedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text("Sign Out", style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => _uploadImage(false),
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              image: _coverPhotoUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(_coverPhotoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          left: 24,
          child: GestureDetector(
            onTap: () => _uploadImage(true),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 12),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 58,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _profilePicUrl.isNotEmpty
                        ? NetworkImage(_profilePicUrl)
                        : null,
                    child: _profilePicUrl.isEmpty
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF0A66C2),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _fullName,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          if (_headline.isNotEmpty)
            Text(
              _headline,
              style: TextStyle(fontSize: 17, color: Colors.grey.shade800),
            ),
          const SizedBox(height: 4),
          if (_location.isNotEmpty)
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  _location,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Open to"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A66C2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _editProfile,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text("Edit profile"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0A66C2),
                    side: const BorderSide(color: Color(0xFF0A66C2)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "About",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF0A66C2)),
                  onPressed: () => _editField(
                    title: "About",
                    initialValue: _about,
                    fieldName: 'about',
                    maxLines: 5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              _about.isEmpty ? "Add a summary about yourself" : _about,
              style: TextStyle(
                height: 1.45,
                fontSize: 15,
                color: _about.isEmpty ? Colors.grey : const Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── BUNDLE DETAIL SCREEN (basic - extend later) ─────────────────────────────
class BundleDetailScreen extends StatelessWidget {
  final String bundleId;

  const BundleDetailScreen({super.key, required this.bundleId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Bundle Details")),
      body: Center(
        child: Text("Bundle ID: $bundleId\n\n(Add bytes viewer here later)"),
      ),
    );
  }
}
