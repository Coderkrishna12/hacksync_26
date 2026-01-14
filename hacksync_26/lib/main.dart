import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hacksync_26/signin.dart';

// Ensure you have generated this file using 'flutterfire configure'
import 'firebase_options.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // High-priority: Initialize Firebase before the app starts
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }
  
  runApp(const ConnectSphereApp());
}

class ConnectSphereApp extends StatelessWidget {
  const ConnectSphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ConnectSphere',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AUTH WRAPPER: Directs user based on login state
// ─────────────────────────────────────────────────────────────────────────────
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        // FIX: If logged in, go to Skills. If not, go to Login.
        if (snapshot.hasData) {
          return const SkillsWorkflow();
        } else {
          return const LoginPage(); // Replace with your actual LoginPage()
        }
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SKILLS WORKFLOW: The 2-Screen Process
// ─────────────────────────────────────────────────────────────────────────────
class SkillsWorkflow extends StatefulWidget {
  const SkillsWorkflow({super.key});

  @override
  State<SkillsWorkflow> createState() => _SkillsWorkflowState();
}

class _SkillsWorkflowState extends State<SkillsWorkflow> {
  final PageController _pageController = PageController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Set<String> _selectedIndustrySkills = {};
  final Set<String> _selectedTopSkills = {};

  final List<String> _industrySkills = [
    'Product Designer', 'Social Media Management', 'Web Development',
    'Mobile App Developer', 'Graphic Designer', 'Digital Marketing',
  ];

  final List<String> _topSkills = [
    'Flutter', 'React Js', 'HTML', 'CSS', 'JavaScript', 'UI/UX',
    'Figma', 'Tailwind', 'Next.js', 'Node.js', 'MongoDB', 'SQL',
  ];

  String _industrySearch = '';
  String _topSearch = '';
  bool _isSaving = false;

  Future<void> _saveSkillsToFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      // Saves to users/{uid}/skills/profile_skills
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('skills')
          .doc('profile_skills')
          .set({
        'industry_skills': _selectedIndustrySkills.toList(),
        'top_skills': _selectedTopSkills.toList(),
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      // If emulator connection fails, it will be caught here
      debugPrint("Firestore Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Connection Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildScreen(
            title: 'Your Industries',
            subtitle: 'Select fields you work in',
            icon: Icons.business_center_outlined,
            searchValue: _industrySearch,
            onSearch: (v) => setState(() => _industrySearch = v),
            masterList: _industrySkills,
            selectedSet: _selectedIndustrySkills,
            isTopSkill: false,
            btnLabel: 'Continue',
            onBtnPressed: _selectedIndustrySkills.isNotEmpty 
                ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease)
                : null,
          ),
          _buildScreen(
            title: 'Top 5 Skills',
            subtitle: 'Pick exactly 5 strengths (${_selectedTopSkills.length}/5)',
            icon: Icons.star_border_rounded,
            searchValue: _topSearch,
            onSearch: (v) => setState(() => _topSearch = v),
            masterList: _topSkills,
            selectedSet: _selectedTopSkills,
            isTopSkill: true,
            showBack: true,
            btnLabel: _isSaving ? 'Saving...' : 'Complete Profile',
            onBtnPressed: (_selectedTopSkills.length == 5 && !_isSaving) ? _saveSkillsToFirestore : null,
          ),
        ],
      ),
    );
  }

  Widget _buildScreen({
    required String title,
    required String subtitle,
    required IconData icon,
    required String searchValue,
    required ValueChanged<String> onSearch,
    required List<String> masterList,
    required Set<String> selectedSet,
    required bool isTopSkill,
    required String btnLabel,
    required VoidCallback? onBtnPressed,
    bool showBack = false,
  }) {
    final filtered = masterList.where((s) => s.toLowerCase().contains(searchValue.toLowerCase())).toList();
    final bool canAdd = searchValue.trim().isNotEmpty && 
                        !masterList.any((s) => s.toLowerCase() == searchValue.toLowerCase().trim()) &&
                        !selectedSet.contains(searchValue.trim());

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showBack) IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease)),
            const SizedBox(height: 10),
            Icon(icon, size: 40, color: Colors.blueAccent),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              onChanged: onSearch,
              decoration: InputDecoration(
                hintText: 'Search or add...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 15),
            if (canAdd)
              ActionChip(
                label: Text('Add "$searchValue"'),
                avatar: const Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    if (isTopSkill) {
                      if (selectedSet.length < 5) selectedSet.add(searchValue.trim());
                    } else {
                      selectedSet.add(searchValue.trim());
                    }
                  });
                },
              ),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...selectedSet.map((s) => _buildChip(s, selectedSet, isTopSkill, true)),
                    ...filtered.where((s) => !selectedSet.contains(s)).map((s) => _buildChip(s, selectedSet, isTopSkill, false)),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: onBtnPressed,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                child: Text(btnLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Set<String> selectedSet, bool isTopSkill, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        setState(() {
          if (val) {
            if (isTopSkill) {
              if (selectedSet.length < 5) selectedSet.add(label);
            } else {
              selectedSet.add(label);
            }
          } else {
            selectedSet.remove(label);
          }
        });
      },
    );
  }
}

