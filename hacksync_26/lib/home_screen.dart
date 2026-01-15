import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// ── MAIN HOME SCREEN WITH BOTTOM NAVIGATION ────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return const BytesFeedContent();
      case 1:
        return const BundlesScreen();
      case 2:
        return const Center(child: Text("Jobs Screen", style: TextStyle(fontSize: 24)));
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0A66C2), // updated to match profile theme
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

// ── BYTES FEED - Vertical scrolling (Reels / Shorts style) ─────────────────
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              _buildActionButton(Icons.favorite_border_rounded, '${(index * 23 + 7) * 10}+'),
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
                Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white70, size: 48),
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

// ── BUNDLES SCREEN - AI-based recommendations ──────────────────────────────
class BundlesScreen extends StatefulWidget {
  const BundlesScreen({super.key});

  @override
  State<BundlesScreen> createState() => _BundlesScreenState();
}

class _BundlesScreenState extends State<BundlesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  List<String> _userSkills = [];
  String _userEducation = "Bachelor"; // Hardcoded as per Python example; adapt if needed
  Set<String> _userInterests = {"technical"}; // Hardcoded as per Python example

  List<Map<String, dynamic>> _recommendations = [];

  // Hardcoded bundles (adapted from career CSV logic; replace with real data/Firestore if needed)
  final List<Map<String, dynamic>> _bundles = [
    {
      "bundle": "Data Science Fundamentals",
      "skills": "python*,pandas,sql,machine learning",
      "growth": "High",
      "min_education": "Bachelor",
      "interests": "technical,data",
      "trend_score": 9.2,
      "industry": "Tech",
      "bundle_path": "From basics to ML models",
      "next_steps": "Enroll in Python course, practice on Kaggle"
    },
    {
      "bundle": "Web Development Mastery",
      "skills": "javascript*,html,css,react",
      "growth": "Medium",
      "min_education": "Diploma",
      "interests": "technical,design",
      "trend_score": 8.5,
      "industry": "Tech",
      "bundle_path": "Frontend to full-stack",
      "next_steps": "Build a portfolio site, learn Node.js"
    },
    {
      "bundle": "Database Expert",
      "skills": "sql*,nosql,database design,python",
      "growth": "High",
      "min_education": "Bachelor",
      "interests": "technical,data",
      "trend_score": 8.8,
      "industry": "Tech",
      "bundle_path": "SQL to advanced queries",
      "next_steps": "Get certified in SQL, work on real datasets"
    },
    {
      "bundle": "AI & Machine Learning",
      "skills": "python*,machine learning,tensorflow,pandas",
      "growth": "High",
      "min_education": "Master",
      "interests": "technical,ai",
      "trend_score": 9.5,
      "industry": "Tech",
      "bundle_path": "Intro AI to deep learning",
      "next_steps": "Study linear algebra, join AI communities"
    },
    // Add more bundles as needed
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final skillsDoc = await _firestore.collection('users').doc(user.uid).collection('skills').doc('profile_skills').get();
      if (skillsDoc.exists) {
        _userSkills = List<String>.from([...?skillsDoc['top_skills'], ...?skillsDoc['industry_skills'], ...?skillsDoc['other_skills']]).map((s) => s.toLowerCase()).toList();
      }

      // TODO: Load education and interests from profile if available
      // For now, using hardcoded as per Python example

      _generateRecommendations();
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _generateRecommendations() {
    final eduLevel = {
      "High School": 1,
      "Diploma": 2,
      "Bachelor": 3,
      "Master": 4,
    };

    final growthWeight = {
      "Low": 0.9,
      "Medium": 1.0,
      "High": 1.2,
    };

    List<Map<String, dynamic>> bundles = [];
    for (var bundle in _bundles) {
      final parsedSkills = _parseSkills(bundle['skills'] as String);
      final userSkillsSet = Set<String>.from(_userSkills);

      if ((eduLevel[_userEducation] ?? 0) < (eduLevel[bundle['min_education']] ?? 0)) continue;

      double matchedWeight = 0;
      double totalWeight = parsedSkills.values.fold(0, (sum, w) => sum + w);
      List<String> matchedSkills = [];
      for (var entry in parsedSkills.entries) {
        if (userSkillsSet.contains(entry.key)) {
          matchedWeight += entry.value;
          matchedSkills.add(entry.key);
        }
      }

      if (matchedWeight == 0) continue;

      final coverage = matchedWeight / totalWeight;
      final trendBonus = (bundle['trend_score'] as double) / 10;
      final growthBonus = growthWeight[bundle['growth']] ?? 1.0;
      final interestBonus = (bundle['interests'] as String).split(',').map((i) => i.trim().toLowerCase()).toSet().intersection(_userInterests).isNotEmpty ? 0.1 : 0;

      final finalScore = 0.6 * coverage + 0.25 * trendBonus + 0.15 * growthBonus + interestBonus;
      final scorePercent = (finalScore * 100).roundToDouble();

      bundles.add({
        "bundle": bundle['bundle'],
        "score": scorePercent,
        "fit": _fitLabel(scorePercent),
        "matched_skills": matchedSkills,
        "missing_skills": parsedSkills.keys.where((k) => !matchedSkills.contains(k)).toList(),
        "industry": bundle['industry'],
        "trend_score": bundle['trend_score'],
        "bundle_path": bundle['bundle_path'],
        "next_steps": bundle['next_steps'],
      });
    }

    bundles.sort((a, b) => b['score'].compareTo(a['score']));
    setState(() => _recommendations = bundles);
  }

  Map<String, double> _parseSkills(String skillString) {
    final skills = <String, double>{};
    for (var s in skillString.split(",")) {
      s = s.trim().toLowerCase();
      if (s.endsWith("*")) {
        skills[s.replaceAll("*", "")] = 3;
      } else {
        skills[s] = 1;
      }
    }
    return skills;
  }

  String _fitLabel(double score) {
    if (score >= 80) return "Strong Match ✅";
    if (score >= 60) return "Good Match 👍";
    return "Emerging Option 🌱";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "🔍 Bundle Recommendations",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_recommendations.isEmpty)
            const Text("No matching bundles found based on your skills."),
          ..._recommendations.take(3).map((r) => Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("🎯 Bundle: ${r['bundle']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("🏷️ Fit Level: ${r['fit']}"),
                      Text("✅ Match Score: ${r['score']}%"),
                      Text("🔥 Trend Score: ${r['trend_score']}/10"),
                      Text("🏭 Industry: ${r['industry']}"),
                      Text("🛣️ Bundle Path: ${r['bundle_path']}"),
                      Text("🧠 Matched Skills: ${r['matched_skills'].join(', ')}"),
                      Text("⚠️ Missing Skills: ${r['missing_skills'].join(', ')}"),
                      Text("📘 Next Steps: ${r['next_steps']}"),
                    ],
                  ),
                ),
              )),
          if (_recommendations.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              "📌 Personalized Guidance:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              "You are closest to *${_recommendations.first['bundle']}* bundles. "
              "Focus on learning *${_recommendations.first['missing_skills'].take(3).join(', ')}* "
              "to unlock more advanced content.",
            ),
          ],
        ],
      ),
    );
  }
}

// ── PROFILE SCREEN - FIXED & ENHANCED ──────────────────────────────────────
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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final profileDoc = await _firestore.collection('users').doc(uid).collection('profile').doc('details').get();

      final eduSnap = await _firestore.collection('users').doc(uid).collection('profile').doc('education').collection('items').orderBy('startDate', descending: true).get();

      final expSnap = await _firestore.collection('users').doc(uid).collection('profile').doc('experience').collection('items').orderBy('startDate', descending: true).get();

      final skillsDoc = await _firestore.collection('users').doc(uid).collection('skills').doc('profile_skills').get();

      if (!mounted) return;

      setState(() {
        _profilePicUrl = profileDoc.data()?['profile_pic_url'] ?? '';
        _coverPhotoUrl = profileDoc.data()?['cover_photo_url'] ?? '';
        _fullName = profileDoc.data()?['fullName'] ?? 'User Name';
        _headline = profileDoc.data()?['headline'] ?? '';
        _location = profileDoc.data()?['location'] ?? '';
        _about = profileDoc.data()?['about'] ?? '';

        education = eduSnap.docs.map((e) => {...e.data(), 'id': e.id}).toList();
        experience = expSnap.docs.map((e) => {...e.data(), 'id': e.id}).toList();
        skills = List<String>.from(
          [...?skillsDoc.data()?['top_skills'], ...?skillsDoc.data()?['other_skills']]
        ).whereType<String>().toList();

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading profile: $e")));
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
      final refPath = isProfilePic ? 'user_profiles/$uid/profile_pic.jpg' : 'user_profiles/$uid/cover_photo.jpg';
      final ref = _storage.ref(refPath);
      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();

      final field = isProfilePic ? 'profile_pic_url' : 'cover_photo_url';

      await _firestore.collection('users').doc(uid).collection('profile').doc('details').set(
        {field: url},
        SetOptions(merge: true),
      );

      setState(() {
        if (isProfilePic) _profilePicUrl = url;
        else _coverPhotoUrl = url;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Photo updated successfully!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
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
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A66C2), foregroundColor: Colors.white),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (result != null && result.trim() != initialValue && result.trim().isNotEmpty) {
      setState(() => _isSaving = true);
      try {
        await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('profile').doc('details').set(
          {fieldName: result.trim()},
          SetOptions(merge: true),
        );

        setState(() {
          switch (fieldName) {
            case 'fullName':
              _fullName = result.trim();
              break;
            case 'headline':
              _headline = result.trim();
              break;
            case 'location':
              _location = result.trim();
              break;
            case 'about':
              _about = result.trim();
              break;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Updated successfully!")));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Update failed: $e")));
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _addOrEditExperience(Map<String, dynamic>? exp) async {
    final isEdit = exp != null;
    final titleController = TextEditingController(text: exp?['title'] as String? ?? '');
    final companyController = TextEditingController(text: exp?['company'] as String? ?? '');

    DateTime? startDate = exp != null && exp['startDate'] is Timestamp ? (exp['startDate'] as Timestamp).toDate() : null;
    DateTime? endDate = exp != null && exp['endDate'] is Timestamp ? (exp['endDate'] as Timestamp).toDate() : null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? "Edit Experience" : "Add Experience"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
              const SizedBox(height: 12),
              TextField(controller: companyController, decoration: const InputDecoration(labelText: "Company")),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => startDate = picked);
                      },
                      child: Text("Start: ${startDate?.toString().split(' ')[0] ?? 'Select'}"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => endDate = picked);
                      },
                      child: Text("End: ${endDate?.toString().split(' ')[0] ?? 'Present'}"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A66C2)),
            child: Text(isEdit ? "Update" : "Add"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSaving = true);
      try {
        final uid = _auth.currentUser!.uid;
        final data = {
          'title': titleController.text.trim(),
          'company': companyController.text.trim(),
          'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
          'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
        };

        final ref = _firestore.collection('users').doc(uid).collection('profile').doc('experience').collection('items');

        if (isEdit && exp!['id'] != null) {
          await ref.doc(exp['id']).set(data, SetOptions(merge: true));
        } else {
          await ref.add(data);
        }

        await _loadProfile();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Experience saved!")));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e")));
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  // Similar pattern for education and skills - you can copy the structure

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        // Your CustomScrollView with header, sections, etc.
        // For brevity, I'm showing only the structure - keep your existing beautiful UI
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildInfoSection()),
            // ... add your other sections (experience, education, skills)
          ],
        ),

        if (_isSaving)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  // Keep y

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _fullName,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF0A66C2)),
                onPressed: () => _editField(title: "Full Name", initialValue: _fullName, fieldName: 'fullName'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _headline,
                  style: TextStyle(fontSize: 17, color: Colors.grey.shade800),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF0A66C2)),
                onPressed: () => _editField(title: "Headline", initialValue: _headline, fieldName: 'headline', maxLines: 2),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 18, color: Colors.grey.shade700),
                  const SizedBox(width: 4),
                  Text(_location, style: TextStyle(color: Colors.grey.shade700, fontSize: 15)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF0A66C2)),
                onPressed: () => _editField(title: "Location", initialValue: _location, fieldName: 'location'),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => _uploadImage(false), // Cover photo
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              image: _coverPhotoUrl.isNotEmpty ? DecorationImage(image: NetworkImage(_coverPhotoUrl), fit: BoxFit.cover) : null,
            ),
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.camera_alt, color: Colors.white.withOpacity(0.8)),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          left: 24,
          child: GestureDetector(
            onTap: () => _uploadImage(true), // Profile pic
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 6))],
                  ),
                  child: CircleAvatar(
                    radius: 58,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _profilePicUrl.isNotEmpty ? NetworkImage(_profilePicUrl) : null,
                    child: _profilePicUrl.isEmpty ? const Icon(Icons.person, size: 60, color: Colors.grey) : null,
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF0A66C2),
                    child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editProfile() async {
  final uid = _auth.currentUser?.uid;
  if (uid == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please sign in first")),
    );
    return;
  }

  // Temporary controllers & variables for editing
  final nameController = TextEditingController(text: _fullName);
  final headlineController = TextEditingController(text: _headline);
  final locationController = TextEditingController(text: _location);
  final aboutController = TextEditingController(text: _about);

  bool isSaving = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Allows full height when keyboard opens
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Stack(
            children: [
              ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Edit Profile",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Full Name
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Full Name",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  // Headline
                  TextField(
                    controller: headlineController,
                    decoration: InputDecoration(
                      labelText: "Headline / Current Role",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Location
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: "Location",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // About
                  TextField(
                    controller: aboutController,
                    decoration: InputDecoration(
                      labelText: "About",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      alignLabelWithHint: true,
                    ),
                    maxLines: 6,
                    minLines: 4,
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final name = nameController.text.trim();
                              final headline = headlineController.text.trim();
                              final location = locationController.text.trim();
                              final about = aboutController.text.trim();

                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Name cannot be empty")),
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);

                              try {
                                final updates = <String, dynamic>{};

                                if (name != _fullName) updates['fullName'] = name;
                                if (headline != _headline) updates['headline'] = headline;
                                if (location != _location) updates['location'] = location;
                                if (about != _about) updates['about'] = about;

                                if (updates.isNotEmpty) {
                                  await _firestore
                                      .collection('users')
                                      .doc(uid)
                                      .collection('profile')
                                      .doc('details')
                                      .set(updates, SetOptions(merge: true));

                                  setState(() {
                                    _fullName = name;
                                    _headline = headline;
                                    _location = location;
                                    _about = about;
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Profile updated successfully!")),
                                  );

                                  Navigator.pop(context);
                                } else {
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Failed to update profile: $e")),
                                );
                              } finally {
                                setModalState(() => isSaving = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A66C2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),

              // Loading overlay when saving
              if (isSaving)
                Container(
                  color: Colors.black.withOpacity(0.1),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildAboutSection() {
    return _cardSection(
      title: "About",
      onEdit: () => _editField(title: "About", initialValue: _about, fieldName: 'about', maxLines: 5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text(
          _about.isEmpty ? "Add a summary about yourself" : _about,
          style: TextStyle(height: 1.45, fontSize: 15, color: _about.isEmpty ? Colors.grey : const Color(0xFF333333)),
        ),
      ),
    );
  }

  Widget _cardSection({
    required String title,
    required Widget child,
    VoidCallback? onEdit,
    VoidCallback? onAdd,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    if (onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20, color: Color(0xFF0A66C2)),
                        onPressed: onEdit,
                      ),
                    if (onAdd != null)
                      IconButton(
                        icon: const Icon(Icons.add, size: 20, color: Color(0xFF0A66C2)),
                        onPressed: onAdd,
                      ),
                  ],
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}