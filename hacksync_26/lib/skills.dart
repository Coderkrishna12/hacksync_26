import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_screen.dart'; // ← Make sure this file exists in the same folder (or adjust path)

class SkillsWorkflow extends StatefulWidget {
  const SkillsWorkflow({super.key});

  @override
  State<SkillsWorkflow> createState() => _SkillsWorkflowState();
}

class _SkillsWorkflowState extends State<SkillsWorkflow> {
  final PageController _pageController = PageController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Selection Sets
  final Set<String> _selectedIndustrySkills = {};
  final Set<String> _selectedTopSkills = {};

  // Master Lists
  final List<String> _industrySkills = [
    'Product Designer',
    'Social Media Management',
    'Web Development',
    'Mobile App Developer',
    'Graphic Designer',
    'Digital Marketing',
    'Data Analyst',
    'Content Creator',
  ];

  final List<String> _topSkills = [
    'Flutter',
    'React Js',
    'HTML',
    'CSS',
    'JavaScript',
    'UI/UX',
    'Figma',
    'Tailwind',
    'Next.js',
    'Node.js',
    'MongoDB',
    'SQL',
  ];

  String _industrySearch = '';
  String _topSearch = '';
  bool _isSaving = false;

  // ────────────────────────────────────────────────
  // ──  Show SnackBar Message                      ──
  // ────────────────────────────────────────────────
  void _showMsg(String msg, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: bgColor,
        duration: const Duration(milliseconds: 2000),
      ),
    );
  }

  // ────────────────────────────────────────────────
  // ──  Firestore Save + Redirect to HomeScreen   ──
  // ────────────────────────────────────────────────
Future<void> _saveSkillsToFirestore() async {
final user = _auth.currentUser;
if (user == null) {
  _showMsg("Not signed in", Colors.orange);
  return;
}

if (!mounted) return;

setState(() => _isSaving = true);

try {
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

  if (!mounted) return;

  // Show success message
  _showMsg("Profile saved!", Colors.green);

  // IMPORTANT: Use a shorter delay or remove it completely
  // Many developers remove delay entirely in 2025+ apps
  await Future.delayed(const Duration(milliseconds: 800));

  if (!mounted) return;

  // Safest navigation patterns (choose ONE):


   Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      );

  // Option C - Pop until root + push new (very clean for onboarding)
  // Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);

} catch (e) {
  if (mounted) {
    _showMsg("Failed to save profile: ${e.toString()}", Colors.red);
  }
} finally {
  if (mounted) {
    setState(() => _isSaving = false);
  }
}
}

// ──  UI Layout Logic                           ──
// ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildScreen(
            title: 'Industries',
            subtitle: 'Which sectors do you work in?',
            icon: Icons.business_center_rounded,
            searchValue: _industrySearch,
            onSearch: (v) => setState(() => _industrySearch = v),
            masterList: _industrySkills,
            selectedSet: _selectedIndustrySkills,
            isTopSkill: false,
            btnLabel: 'Next: Top Skills',
            onBtnPressed: _selectedIndustrySkills.isNotEmpty
                ? () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    )
                : null,
            showBack: false,
          ),
          _buildScreen(
            title: 'Top 5 Skills',
            subtitle: 'Select exactly 5 strengths (${_selectedTopSkills.length}/5)',
            icon: Icons.verified_rounded,
            searchValue: _topSearch,
            onSearch: (v) => setState(() => _topSearch = v),
            masterList: _topSkills,
            selectedSet: _selectedTopSkills,
            isTopSkill: true,
            showBack: true,
            btnLabel: _isSaving ? 'Saving...' : 'Complete Profile',
            onBtnPressed: (_selectedTopSkills.length == 5 && !_isSaving)
                ? _saveSkillsToFirestore
                : null,
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
    final trimmedSearch = searchValue.trim().toLowerCase();
    final filtered = masterList
        .where((s) => s.toLowerCase().contains(trimmedSearch))
        .toList();

    final searchTrimmed = searchValue.trim();
    final bool canAdd = searchTrimmed.isNotEmpty &&
        !masterList.any((s) => s.toLowerCase() == trimmedSearch) &&
        !selectedSet.contains(searchTrimmed);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showBack)
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
              ),
            Icon(icon, size: 40, color: const Color(0xFF2563EB)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
            const SizedBox(height: 24),

            // Search Bar
            TextField(
              onChanged: onSearch,
              decoration: InputDecoration(
                hintText: 'Search or type to add custom...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Add Custom Chip
            if (canAdd)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ActionChip(
                  label: Text('Add "$searchTrimmed"'),
                  avatar: const Icon(Icons.add, size: 16),
                  backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                  onPressed: () {
                    setState(() {
                      if (isTopSkill) {
                        if (selectedSet.length < 5) {
                          selectedSet.add(searchTrimmed);
                        }
                      } else {
                        selectedSet.add(searchTrimmed);
                      }
                    });
                  },
                ),
              ),

            // Chips Display
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Selected first
                    ...selectedSet.map(
                      (s) => _buildChip(s, selectedSet, isTopSkill, true),
                    ),
                    // Unselected matches
                    ...filtered
                        .where((s) => !selectedSet.contains(s))
                        .map((s) => _buildChip(s, selectedSet, isTopSkill, false)),
                  ],
                ),
              ),
            ),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onBtnPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  disabledBackgroundColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  btnLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(
    String label,
    Set<String> selectedSet,
    bool isTopSkill,
    bool isSelected,
  ) {
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
      selectedColor: const Color(0xFF2563EB).withOpacity(0.15),
      checkmarkColor: const Color(0xFF2563EB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}