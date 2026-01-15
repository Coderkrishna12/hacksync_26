import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'home_screen.dart'; // adjust path if needed
import 'results_screen.dart';

class SkillsWorkflow extends StatefulWidget {
  const SkillsWorkflow({super.key});

  @override
  State<SkillsWorkflow> createState() => _SkillsWorkflowState();
}

class _SkillsWorkflowState extends State<SkillsWorkflow> {
  final PageController _pageController = PageController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Form Data ────────────────────────────────────────────────
  final Set<String> _selectedIndustries = {};
  final Set<String> _selectedSkills = {};
  String? _selectedEducation;
  final Set<String> _selectedInterests = {};

  // ── Master lists ─────────────────────────────────────────────
  final List<String> _industries = [
    'Product Designer',
    'Social Media Management',
    'Web Development',
    'Mobile App Developer',
    'Graphic Designer',
    'Digital Marketing',
    'Data Analyst',
    'Content Creator',
    'AI / Machine Learning',
    'Cybersecurity',
  ];

  final List<String> _skills = [
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
    'Python',
    'Machine Learning',
    'AWS',
  ];

  final List<String> _educationLevels = [
    'High School',
    'Diploma',
    'Bachelor',
    'Master',
    'PhD',
  ];

  final List<String> _interests = [
    'technical',
    'creative',
    'analytical',
    'business',
    'leadership',
    'research',
    'design',
    'marketing',
    'data',
    'ai_ml',
  ];

  // ── State ────────────────────────────────────────────────────
  bool _isLoading = false;
  bool _isChecking = true;
  bool _hasExistingData = false;
  bool _showForm =
      false; // Controls if form is visible (when editing or no data)

  String _searchInd = '';
  String _searchSkill = '';
  String _searchInterest = '';

  List<String> _currentSkills = [];
  String _currentEducation = '';
  List<String> _currentInterests = [];

  @override
  void initState() {
    super.initState();
    _checkExistingData();
  }

  Future<void> _checkExistingData() async {
    final user = _auth.currentUser;
    if (user == null) {
      _showSnack("Not signed in", Colors.orange);
      setState(() {
        _isChecking = false;
        _showForm = true; // Show form if not signed in
      });
      return;
    }

    try {
      final skillsDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('skills')
          .doc('profile_skills')
          .get();

      final profileDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('details')
          .get();

      if (skillsDoc.exists && profileDoc.exists) {
        final topSkills = List<String>.from(skillsDoc['top_skills'] ?? []);
        final education = profileDoc['education'] as String?;
        final interests = List<String>.from(profileDoc['interests'] ?? []);

        if (topSkills.length == 5 &&
            education != null &&
            interests.isNotEmpty) {
          _currentSkills = topSkills;
          _currentEducation = education;
          _currentInterests = interests;
          setState(() => _hasExistingData = true);
          return;
        }
      }
    } catch (e) {
      _showSnack("Error checking profile: $e", Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _showForm = !_hasExistingData; // Show form only if no data
        });
      }
    }
  }

  Future<void> _fetchRecommendations(
    List<String> skills,
    String education,
    List<String> interests,
  ) async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.0.102:5000/recommend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'skills': skills,
          'education': education,
          'interests': interests,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final careers = json['recommendations'] ?? [];

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultsScreen(
                careers: careers,
                onUpdatePreferences: _startEditing,
              ),
            ),
          );
        }
      } else {
        _showSnack("Server error: ${response.statusCode}", Colors.red);
      }
    } catch (e) {
      _showSnack("Connection failed: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAndFetchRecommendations() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_selectedIndustries.isEmpty ||
        _selectedSkills.length != 5 ||
        _selectedEducation == null ||
        _selectedInterests.isEmpty) {
      _showSnack("Please complete all sections", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('skills')
          .doc('profile_skills')
          .set({
            'industry_skills': _selectedIndustries.toList(),
            'top_skills': _selectedSkills.toList(),
            'last_updated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('details')
          .set({
            'education': _selectedEducation,
            'interests': _selectedInterests.toList(),
          }, SetOptions(merge: true));

      _showSnack("Preferences saved!", Colors.green);

      // Update local current data
      _currentSkills = _selectedSkills.toList();
      _currentEducation = _selectedEducation!;
      _currentInterests = _selectedInterests.toList();

      // Fetch recommendations with new data
      await _fetchRecommendations(
        _currentSkills,
        _currentEducation,
        _currentInterests,
      );

      // Hide form after saving
      setState(() => _showForm = false);
    } catch (e) {
      _showSnack("Save failed: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startEditing() async {
    Navigator.pop(context); // Pop results screen

    await _loadCurrentDataIntoForm();

    setState(() => _showForm = true);
    _pageController.jumpToPage(0);
  }

  Future<void> _loadCurrentDataIntoForm() async {
    setState(() {
      _selectedIndustries.clear();
      _selectedIndustries.addAll(
        _currentSkills,
      ); // Wait, industry is different? Adjust if needed

      _selectedSkills.clear();
      _selectedSkills.addAll(_currentSkills);

      _selectedEducation = _currentEducation;

      _selectedInterests.clear();
      _selectedInterests.addAll(_currentInterests);
    });
  }

  void _getRecommendationsWithExisting() async {
    await _fetchRecommendations(
      _currentSkills,
      _currentEducation,
      _currentInterests,
    );
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking || _isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 24),
              Text("Loading..."),
            ],
          ),
        ),
      );
    }

    // If data exists and not editing, show two buttons
    if (_hasExistingData && !_showForm) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Your Preferences"),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _getRecommendationsWithExisting,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  "Get Career Recommendations",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () {
                  setState(() => _showForm = true);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  "Change Preferences",
                  style: TextStyle(fontSize: 16, color: Color(0xFF2563EB)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show the form (either first time or editing)
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_hasExistingData ? "Update Preferences" : "Setup Profile"),
        centerTitle: true,
        actions: [
          if (_hasExistingData)
            TextButton(
              onPressed: () {
                setState(() => _showForm = false);
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildPage(
            title: 'Industries / Fields',
            subtitle: 'Which areas do you work in or prefer?',
            icon: Icons.business_center,
            search: _searchInd,
            onSearch: (v) => setState(() => _searchInd = v),
            list: _industries,
            selected: _selectedIndustries,
            isLimited: false,
            btnLabel: 'Next: Skills',
            onNext: _selectedIndustries.isNotEmpty
                ? () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  )
                : null,
            showBack: false,
          ),
          _buildPage(
            title: 'Top 5 Skills',
            subtitle:
                'Select your strongest skills (${_selectedSkills.length}/5)',
            icon: Icons.verified,
            search: _searchSkill,
            onSearch: (v) => setState(() => _searchSkill = v),
            list: _skills,
            selected: _selectedSkills,
            isLimited: true,
            maxLimit: 5,
            btnLabel: 'Next: Education',
            onNext: _selectedSkills.length == 5
                ? () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  )
                : null,
            showBack: true,
          ),
          _buildEducationPage(),
          _buildPage(
            title: 'Interests',
            subtitle: 'What motivates you most?',
            icon: Icons.favorite,
            search: _searchInterest,
            onSearch: (v) => setState(() => _searchInterest = v),
            list: _interests,
            selected: _selectedInterests,
            isLimited: false,
            btnLabel: 'Save & Get Recommendations',
            onNext: _selectedInterests.isNotEmpty && !_isLoading
                ? _saveAndFetchRecommendations
                : null,
            showBack: true,
          ),
        ],
      ),
    );
  }

  // ── _buildPage, _chip, _buildEducationPage ──────────────────

  Widget _buildPage({
    required String title,
    required String subtitle,
    required IconData icon,
    required String search,
    required ValueChanged<String> onSearch,
    required List<String> list,
    required Set<String> selected,
    required bool isLimited,
    int maxLimit = 5,
    required String btnLabel,
    VoidCallback? onNext,
    required bool showBack,
  }) {
    final q = search.trim().toLowerCase();
    final filtered = list.where((s) => s.toLowerCase().contains(q)).toList();

    final canAddCustom =
        search.trim().isNotEmpty &&
        !list.any((s) => s.toLowerCase() == q) &&
        !selected.contains(search.trim());

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showBack)
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
              ),
            Icon(icon, size: 42, color: const Color(0xFF2563EB)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[700], fontSize: 15),
            ),
            const SizedBox(height: 24),
            TextField(
              onChanged: onSearch,
              decoration: InputDecoration(
                hintText: 'Search or add custom...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF2563EB),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (canAddCustom)
              ActionChip(
                label: Text('Add "${search.trim()}"'),
                avatar: const Icon(Icons.add),
                backgroundColor: const Color(0xFF2563EB).withOpacity(0.15),
                onPressed: () {
                  setState(() {
                    if (!isLimited || selected.length < maxLimit)
                      selected.add(search.trim());
                  });
                },
              ),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ...selected.map(
                      (s) => _chip(s, selected, isLimited, maxLimit, true),
                    ),
                    ...filtered
                        .where((s) => !selected.contains(s))
                        .map(
                          (s) => _chip(s, selected, isLimited, maxLimit, false),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  btnLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(
    String label,
    Set<String> selectedSet,
    bool limit,
    int max,
    bool isSelected,
  ) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        setState(() {
          if (val) {
            if (!limit || selectedSet.length < max) selectedSet.add(label);
          } else {
            selectedSet.remove(label);
          }
        });
      },
      selectedColor: const Color(0xFF2563EB).withOpacity(0.2),
      checkmarkColor: const Color(0xFF2563EB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? const Color(0xFF2563EB) : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildEducationPage() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                    ),
                    const Icon(
                      Icons.school,
                      size: 42,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Highest Education Level',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ..._educationLevels.map(
                      (lvl) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: RadioListTile<String>(
                          title: Text(lvl),
                          value: lvl,
                          groupValue: _selectedEducation,
                          activeColor: const Color(0xFF2563EB),
                          onChanged: (v) =>
                              setState(() => _selectedEducation = v),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _selectedEducation != null
                    ? () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      )
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Next: Interests',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
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
