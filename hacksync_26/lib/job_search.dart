import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ── JOBS SECTION - Post & View Jobs ────────────────────────────────────────
class JobsSection extends StatefulWidget {
  const JobsSection({super.key});

  @override
  State<JobsSection> createState() => _JobsSectionState();
}

class _JobsSectionState extends State<JobsSection> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  bool _isPosting = false;
  List<String> _userSkills = [];
  List<Map<String, dynamic>> _allJobs = [];
  List<Map<String, dynamic>> _matchedJobs = [];

  // Controllers for posting new job
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skillsController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserSkillsAndJobs();
  }

  Future<void> _loadUserSkillsAndJobs() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      // 1. Load user's skills - safely handle missing document & missing fields
      final skillsDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('skills')
          .doc('profile_skills')
          .get();

      _userSkills = [];

      if (skillsDoc.exists) {
        final data = skillsDoc.data() ?? {};

        // Safely get each array (default to empty list if missing)
        final topSkills = (data['top_skills'] as List<dynamic>?)?.cast<String>() ?? [];
        final otherSkills = (data['other_skills'] as List<dynamic>?)?.cast<String>() ?? [];
        final industrySkills = (data['industry_skills'] as List<dynamic>?)?.cast<String>() ?? [];

        _userSkills = [...topSkills, ...otherSkills, ...industrySkills]
            .map((s) => (s as String).toLowerCase().trim())
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList();
      }

      // 2. Load all jobs (limited to prevent overload)
      final jobsSnap = await _firestore
          .collection('jobs')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final allJobsList = jobsSnap.docs.map((doc) => {
            'id': doc.id,
            ...doc.data(),
          }).toList();

      // 3. Filter matched jobs safely
      final matched = allJobsList.where((job) {
        final requiredSkills = (job['requiredSkills'] as List<dynamic>?)
                ?.map((s) => (s as String?)?.toLowerCase().trim() ?? '')
                .where((s) => s.isNotEmpty)
                .toList() ??
            [];
        return requiredSkills.any((req) => _userSkills.contains(req));
      }).toList();

      if (mounted) {
        setState(() {
          _allJobs = allJobsList;
          _matchedJobs = matched;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading jobs: $e")),
        );
      }
    }
  }

  Future<void> _postNewJob() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please sign in first")),
      );
      return;
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Post a New Job",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Job Title",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: "Job Description",
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _skillsController,
                decoration: const InputDecoration(
                  labelText: "Required Skills (comma separated)",
                  border: OutlineInputBorder(),
                  hintText: "e.g. Flutter, Firebase, UI/UX",
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: "Location (optional)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isPosting
                      ? null
                      : () async {
                          final title = _titleController.text.trim();
                          final description = _descriptionController.text.trim();
                          final skillsText = _skillsController.text.trim();
                          final location = _locationController.text.trim();

                          if (title.isEmpty || description.isEmpty || skillsText.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "Title, description & skills are required")),
                            );
                            return;
                          }

                          setState(() => _isPosting = true);

                          try {
                            final skills = skillsText
                                .split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList();

                            await _firestore.collection('jobs').add({
                              'title': title,
                              'description': description,
                              'requiredSkills': skills,
                              'location': location.isNotEmpty ? location : null,
                              'postedBy': uid,
                              'createdAt': FieldValue.serverTimestamp(),
                              'applicants': [],
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Job posted successfully!")),
                            );

                            _titleController.clear();
                            _descriptionController.clear();
                            _skillsController.clear();
                            _locationController.clear();

                            Navigator.pop(context);
                            await _loadUserSkillsAndJobs(); // Refresh
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Failed to post job: $e")),
                            );
                          } finally {
                            setState(() => _isPosting = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A66C2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isPosting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("Post Job", style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _postNewJob,
        backgroundColor: const Color(0xFF0A66C2),
        icon: const Icon(Icons.add),
        label: const Text("Post Job"),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              tabs: const [
                Tab(text: "All Jobs"),
                Tab(text: "Matching Your Skills"),
              ],
              labelColor: const Color(0xFF0A66C2),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF0A66C2),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // All Jobs
                  RefreshIndicator(
                    onRefresh: _loadUserSkillsAndJobs,
                    child: _allJobs.isEmpty
                        ? const Center(
                            child: Text("No jobs posted yet",
                                style: TextStyle(fontSize: 16, color: Colors.grey)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _allJobs.length,
                            itemBuilder: (context, index) {
                              final job = _allJobs[index];
                              return JobCard(job: job);
                            },
                          ),
                  ),
                  // Matched Jobs
                  RefreshIndicator(
                    onRefresh: _loadUserSkillsAndJobs,
                    child: _matchedJobs.isEmpty
                        ? const Center(
                            child: Text(
                                "No matching jobs found.\nAdd more skills to your profile!",
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _matchedJobs.length,
                            itemBuilder: (context, index) {
                              final job = _matchedJobs[index];
                              return JobCard(job: job, highlightMatch: true);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Job Card Widget ────────────────────────────────────────────────────────
class JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final bool highlightMatch;

  const JobCard({
    super.key,
    required this.job,
    this.highlightMatch = false,
  });

  @override
  Widget build(BuildContext context) {
    final skills = (job['requiredSkills'] as List<dynamic>?)?.cast<String>() ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job['title'] ?? 'No Title',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (highlightMatch)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Skill Match",
                      style: TextStyle(color: Colors.green.shade800, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              job['description'] ?? '',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.map((skill) => Chip(
                    label: Text(skill),
                    backgroundColor: const Color(0xFFEAF3FF),
                    labelStyle: const TextStyle(color: Color(0xFF0A66C2)),
                  )).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  job['location'] ?? 'Remote / Not specified',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const Spacer(),
                Text(
                  job['createdAt'] != null
                      ? _timeAgo((job['createdAt'] as Timestamp).toDate())
                      : '',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}