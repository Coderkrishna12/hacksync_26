import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ── JOBS SECTION - Post & View & Apply to Jobs ───────────────────────────────
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
  List<Map<String, dynamic>> _myPostedJobs = [];

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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _skillsController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserSkillsAndJobs() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Load user's skills
      final skillsDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('skills')
          .doc('profile_skills')
          .get();

      _userSkills = [];

      if (skillsDoc.exists) {
        final data = skillsDoc.data() ?? {};
        final topSkills =
            (data['top_skills'] as List<dynamic>?)?.cast<String>() ?? [];
        final otherSkills =
            (data['other_skills'] as List<dynamic>?)?.cast<String>() ?? [];
        final industrySkills =
            (data['industry_skills'] as List<dynamic>?)?.cast<String>() ?? [];

        _userSkills = [...topSkills, ...otherSkills, ...industrySkills]
            .map((s) => (s as String).toLowerCase().trim())
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList();
      }

      // 2. Load recent jobs
      final jobsSnap = await _firestore
          .collection('jobs')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final allJobsList = jobsSnap.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // 3. Find matching jobs
      final matched = allJobsList.where((job) {
        final requiredSkills =
            (job['requiredSkills'] as List<dynamic>?)
                ?.map((s) => (s as String?)?.toLowerCase().trim() ?? '')
                .where((s) => s.isNotEmpty)
                .toList() ??
            [];
        return requiredSkills.any((req) => _userSkills.contains(req));
      }).toList();

      // 4. Load my posted jobs
      final myJobsSnap = await _firestore
          .collection('jobs')
          .where('postedBy', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final myPostedJobsList = myJobsSnap.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      if (mounted) {
        setState(() {
          _allJobs = allJobsList;
          _matchedJobs = matched;
          _myPostedJobs = myPostedJobsList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error loading jobs: $e")));
      }
    }
  }

  Future<void> _postNewJob() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please sign in first")));
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
              const Text(
                "Post a New Job",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
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
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _skillsController,
                decoration: const InputDecoration(
                  labelText: "Required Skills (comma separated)",
                  border: OutlineInputBorder(),
                  hintText: "e.g. Flutter, Firebase, UI/UX, Leadership",
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
                          final description = _descriptionController.text
                              .trim();
                          final skillsText = _skillsController.text.trim();
                          final location = _locationController.text.trim();

                          if (title.isEmpty ||
                              description.isEmpty ||
                              skillsText.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Title, description & skills are required",
                                ),
                              ),
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
                                content: Text("Job posted successfully!"),
                              ),
                            );

                            _titleController.clear();
                            _descriptionController.clear();
                            _skillsController.clear();
                            _locationController.clear();

                            Navigator.pop(context);
                            await _loadUserSkillsAndJobs();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Failed to post job: $e")),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _isPosting = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A66C2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isPosting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
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
        length: 3,
        child: Column(
          children: [
            TabBar(
              tabs: const [
                Tab(text: "All Jobs"),
                Tab(text: "Matching Your Skills"),
                Tab(text: "My Posted Jobs"),
              ],
              labelColor: const Color(0xFF0A66C2),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF0A66C2),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // All Jobs Tab
                  RefreshIndicator(
                    onRefresh: _loadUserSkillsAndJobs,
                    child: _allJobs.isEmpty
                        ? const Center(
                            child: Text(
                              "No jobs posted yet",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _allJobs.length,
                            itemBuilder: (context, index) {
                              final job = _allJobs[index];
                              return JobCard(job: job);
                            },
                          ),
                  ),

                  // Matched Jobs Tab
                  RefreshIndicator(
                    onRefresh: _loadUserSkillsAndJobs,
                    child: _matchedJobs.isEmpty
                        ? const Center(
                            child: Text(
                              "No matching jobs found.\nTry adding more skills to your profile!",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
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

                  // My Posted Jobs Tab
                  RefreshIndicator(
                    onRefresh: _loadUserSkillsAndJobs,
                    child: _myPostedJobs.isEmpty
                        ? const Center(
                            child: Text(
                              "You haven't posted any jobs yet.\nTap the button to post one!",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _myPostedJobs.length,
                            itemBuilder: (context, index) {
                              final job = _myPostedJobs[index];
                              return JobCard(job: job, highlightMatch: false);
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

// ── Job Card with Apply Dialog ───────────────────────────────────────────────
class JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final bool highlightMatch;

  const JobCard({super.key, required this.job, this.highlightMatch = false});

  @override
  Widget build(BuildContext context) {
    final skills =
        (job['requiredSkills'] as List<dynamic>?)?.cast<String>() ?? [];

    return GestureDetector(
      onTap: () => _showJobDetailsDialog(context),
      child: Card(
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (highlightMatch)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Skill Match",
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                job['description']?.substring(
                      0,
                      job['description'].length > 120 ? 120 : null,
                    ) ??
                    '',
                style: TextStyle(color: Colors.grey.shade700),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills
                    .take(5)
                    .map(
                      (skill) => Chip(
                        label: Text(skill),
                        backgroundColor: const Color(0xFFEAF3FF),
                        labelStyle: const TextStyle(color: Color(0xFF0A66C2)),
                      ),
                    )
                    .toList(),
              ),
              if (skills.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "+${skills.length - 5} more",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
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
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "Tap to view details →",
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJobDetailsDialog(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please sign in to view details")),
      );
      return;
    }

    final bool isPoster = job['postedBy'] == uid;
    final applicants =
        (job['applicants'] as List<dynamic>?)?.cast<String>() ?? [];
    final bool alreadyApplied = applicants.contains(uid);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(job['title'] ?? 'Job Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                job['description'] ?? 'No description provided',
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 20),
              const Text(
                "Required Skills:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    (job['requiredSkills'] as List<dynamic>?)
                        ?.cast<String>()
                        ?.map(
                          (s) => Chip(
                            label: Text(s),
                            backgroundColor: Colors.blue.shade50,
                            labelStyle: const TextStyle(
                              color: Color(0xFF0A66C2),
                            ),
                          ),
                        )
                        ?.toList() ??
                    [const Text("No skills listed")],
              ),
              const SizedBox(height: 16),
              Text(
                "Location: ${job['location'] ?? 'Remote / Not specified'}",
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 12),
              Text(
                "Posted: ${job['createdAt'] != null ? _timeAgo((job['createdAt'] as Timestamp).toDate()) : 'Unknown'}",
                style: TextStyle(color: Colors.grey.shade600),
              ),
              if (isPoster)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    "Applicants: ${applicants.length}",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          if (isPoster && applicants.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showApplicantsList(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A66C2),
                foregroundColor: Colors.white,
              ),
              child: const Text("View Applicants"),
            ),
          if (!isPoster)
            if (alreadyApplied)
              OutlinedButton(
                onPressed: null,
                child: const Text("Already Applied"),
              )
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.send, size: 18),
                label: const Text("Apply Now"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A66C2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await _applyToJob(context, uid);
                },
              ),
        ],
      ),
    );
  }

  Future<void> _showApplicantsList(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final applicantsUids =
          (job['applicants'] as List<dynamic>?)?.cast<String>() ?? [];
      final requiredSkills =
          (job['requiredSkills'] as List<dynamic>?)
              ?.cast<String>()
              .map((s) => s.toLowerCase().trim())
              .toList() ??
          [];

      List<Map<String, dynamic>> applicantProfiles = [];

      for (String appUid in applicantsUids) {
        // Fetch user profile
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(appUid)
            .get();
        final userData = userDoc.data() ?? {};
        final name =
            userData['name'] ?? userData['displayName'] ?? 'Anonymous User';

        // Fetch user skills
        final skillsDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(appUid)
            .collection('skills')
            .doc('profile_skills')
            .get();

        List<String> appSkills = [];
        if (skillsDoc.exists) {
          final skillsData = skillsDoc.data() ?? {};
          final topSkills =
              (skillsData['top_skills'] as List<dynamic>?)?.cast<String>() ??
              [];
          final otherSkills =
              (skillsData['other_skills'] as List<dynamic>?)?.cast<String>() ??
              [];
          final industrySkills =
              (skillsData['industry_skills'] as List<dynamic>?)
                  ?.cast<String>() ??
              [];

          appSkills = [...topSkills, ...otherSkills, ...industrySkills]
              .map((s) => s.toLowerCase().trim())
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList();
        }

        // Calculate match count
        final matchCount = appSkills
            .where((skill) => requiredSkills.contains(skill))
            .length;

        applicantProfiles.add({
          'uid': appUid,
          'name': name,
          'skills': appSkills,
          'matchCount': matchCount,
        });
      }

      // Sort by matchCount descending (best match first)
      applicantProfiles.sort(
        (a, b) => b['matchCount'].compareTo(a['matchCount']),
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Applied Candidates'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: applicantProfiles.isEmpty
                  ? const Center(child: Text('No applicants yet'))
                  : ListView.builder(
                      itemCount: applicantProfiles.length,
                      itemBuilder: (context, index) {
                        final applicant = applicantProfiles[index];
                        final matchingSkills = applicant['skills']
                            .where((skill) => requiredSkills.contains(skill))
                            .toList();

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  applicant['name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Skill Matches: ${applicant['matchCount']} / ${requiredSkills.length}',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (matchingSkills.isNotEmpty)
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: matchingSkills
                                        .map(
                                          (skill) => Chip(
                                            label: Text(skill),
                                            backgroundColor:
                                                Colors.green.shade100,
                                          ),
                                        )
                                        .toList(),
                                  )
                                else
                                  const Text(
                                    'No matching skills',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error loading applicants: $e")));
      }
    }
  }

  Future<void> _applyToJob(BuildContext context, String uid) async {
    try {
      await FirebaseFirestore.instance.collection('jobs').doc(job['id']).update(
        {
          'applicants': FieldValue.arrayUnion([uid]),
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Application submitted successfully! 🎉"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to apply: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 30) return '${(diff.inDays / 30).round()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
