import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ResumePreviewScreen extends StatefulWidget {
  final Map<String, dynamic> career;

  const ResumePreviewScreen({super.key, required this.career});

  @override
  State<ResumePreviewScreen> createState() => _ResumePreviewScreenState();
}

class _ResumePreviewScreenState extends State<ResumePreviewScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _resumeResult;
  String? _pdfFilePath;
  late String careerTitle;

  @override
  void initState() {
    super.initState();
    careerTitle = widget.career['career']?.toString() ?? 'Career Opportunity';
    _generateResume();
  }

  /// Fetches ALL user data from Firebase and generates resume
  Future<void> _generateResume() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = "Please sign in to generate your resume.";
        _isLoading = false;
      });
      return;
    }

    try {
      // ═══════════════════════════════════════════════════════════════
      // 1. FETCH ALL FIREBASE DATA
      // ═══════════════════════════════════════════════════════════════

      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      // Fetch profile details
      final profileSnap = await userDocRef
          .collection('profile')
          .doc('details')
          .get();

      // Fetch skills
      final skillsSnap = await userDocRef
          .collection('skills')
          .doc('profile_skills')
          .get();

      // Fetch education (if stored separately)
      final educationSnap = await userDocRef.collection('education').get();

      // Fetch experience/work history
      final experienceSnap = await userDocRef.collection('experience').get();

      // Fetch projects
      final projectsSnap = await userDocRef.collection('projects').get();

      // Fetch certifications
      final certificationsSnap = await userDocRef
          .collection('certifications')
          .get();

      // Fetch achievements/awards
      final achievementsSnap = await userDocRef
          .collection('achievements')
          .get();

      // ═══════════════════════════════════════════════════════════════
      // 2. BUILD USER INFO WITH SAFE DEFAULTS
      // ═══════════════════════════════════════════════════════════════

      // Basic info with fallbacks
      String name = user.displayName ?? 'Your Name';
      String email = user.email ?? 'your.email@example.com';
      String phone = '';
      String bio = '';
      String location = '';
      String linkedin = '';
      String github = '';
      String portfolio = '';

      // Skills
      List<String> technicalSkills = [];
      List<String> softSkills = [];
      String educationLevel = 'Bachelor';

      // Collections
      List<Map<String, dynamic>> educationList = [];
      List<Map<String, dynamic>> experienceList = [];
      List<Map<String, dynamic>> projectsList = [];
      List<Map<String, dynamic>> certificationsList = [];
      List<Map<String, dynamic>> achievementsList = [];

      // ── Parse profile data ──────────────────────────────────────
      if (profileSnap.exists) {
        final data = profileSnap.data()!;
        name = data['name'] as String? ?? name;
        phone = data['phone'] as String? ?? '';
        bio =
            data['bio'] as String? ??
            data['about'] as String? ??
            data['summary'] as String? ??
            '';
        location = data['location'] as String? ?? data['city'] as String? ?? '';
        linkedin = data['linkedin'] as String? ?? '';
        github = data['github'] as String? ?? '';
        portfolio =
            data['portfolio'] as String? ?? data['website'] as String? ?? '';
      }

      // ── Parse skills data ───────────────────────────────────────
      if (skillsSnap.exists) {
        final data = skillsSnap.data()!;
        technicalSkills = List<String>.from(
          data['top_skills'] ??
              data['technical_skills'] ??
              data['skills'] ??
              [],
        );
        softSkills = List<String>.from(
          data['soft_skills'] ?? data['other_skills'] ?? [],
        );
        educationLevel = data['education'] as String? ?? educationLevel;
      }

      // ── Parse education ─────────────────────────────────────────
      for (var doc in educationSnap.docs) {
        final data = doc.data();
        educationList.add({
          'degree': data['degree'] ?? data['course'] ?? '',
          'institution':
              data['institution'] ?? data['school'] ?? data['college'] ?? '',
          'year': data['year'] ?? data['graduation_year'] ?? '',
          'grade': data['grade'] ?? data['cgpa'] ?? data['percentage'] ?? '',
          'field':
              data['field'] ?? data['major'] ?? data['specialization'] ?? '',
        });
      }

      // ── Parse experience ────────────────────────────────────────
      for (var doc in experienceSnap.docs) {
        final data = doc.data();
        experienceList.add({
          'title': data['title'] ?? data['position'] ?? data['role'] ?? '',
          'company': data['company'] ?? data['organization'] ?? '',
          'duration':
              data['duration'] ??
              '${data['start_date'] ?? ''} - ${data['end_date'] ?? ''}',
          'description': data['description'] ?? data['responsibilities'] ?? '',
          'achievements': List<String>.from(data['achievements'] ?? []),
          'location': data['location'] ?? '',
          'type':
              data['type'] ??
              data['employment_type'] ??
              '', // Full-time, Internship, etc.
        });
      }

      // ── Parse projects ──────────────────────────────────────────
      for (var doc in projectsSnap.docs) {
        final data = doc.data();
        projectsList.add({
          'name': data['name'] ?? data['title'] ?? '',
          'description': data['description'] ?? '',
          'technologies': List<String>.from(
            data['technologies'] ?? data['tech_stack'] ?? [],
          ),
          'link': data['link'] ?? data['github'] ?? data['url'] ?? '',
          'role': data['role'] ?? '',
          'duration': data['duration'] ?? '',
          'highlights': List<String>.from(
            data['highlights'] ?? data['features'] ?? [],
          ),
        });
      }

      // ── Parse certifications ────────────────────────────────────
      for (var doc in certificationsSnap.docs) {
        final data = doc.data();
        certificationsList.add({
          'name': data['name'] ?? data['title'] ?? '',
          'issuer': data['issuer'] ?? data['organization'] ?? '',
          'date': data['date'] ?? data['issued_date'] ?? '',
          'id': data['id'] ?? data['credential_id'] ?? '',
          'url': data['url'] ?? data['link'] ?? '',
        });
      }

      // ── Parse achievements ──────────────────────────────────────
      for (var doc in achievementsSnap.docs) {
        final data = doc.data();
        achievementsList.add({
          'title': data['title'] ?? data['name'] ?? '',
          'description': data['description'] ?? '',
          'date': data['date'] ?? data['year'] ?? '',
          'issuer': data['issuer'] ?? data['organization'] ?? '',
        });
      }

      // ═══════════════════════════════════════════════════════════════
      // 3. PREPARE COMPREHENSIVE PAYLOAD
      // ═══════════════════════════════════════════════════════════════

      final payload = {
        // Basic user information
        'user_info': {
          'name': name,
          'email': email,
          'phone': phone,
          'location': location,
          'linkedin': linkedin,
          'github': github,
          'portfolio': portfolio,
          'bio': bio.isEmpty
              ? 'Motivated professional passionate about ${careerTitle.toLowerCase()}. '
                    'Eager to contribute strong skills and drive meaningful impact.'
              : bio,
          'education': educationLevel,
          'skills': technicalSkills,
          'soft_skills': softSkills,
        },

        // Career-specific information
        'career': careerTitle,
        'job_description':
            widget.career['next_steps'] ??
            widget.career['career_path'] ??
            'Entry-level to mid-level role in $careerTitle. '
                'Focus on leveraging technical expertise and continuous learning.',

        // Career match data from previous screen
        'matched_skills': widget.career['matched_skills'] ?? [],
        'missing_skills': widget.career['missing_skills'] ?? [],
        'career_score': widget.career['score'] ?? 0,
        'industry': widget.career['industry'] ?? '',
        'trend_score': widget.career['trend_score'] ?? 0,

        // Detailed sections
        'education_list': educationList,
        'experience_list': experienceList,
        'projects_list': projectsList,
        'certifications_list': certificationsList,
        'achievements_list': achievementsList,
      };

      print('═══ Sending Resume Request ═══');
      print('Career: $careerTitle');
      print(
        'Skills: ${technicalSkills.length} technical, ${softSkills.length} soft',
      );
      print('Education: ${educationList.length} entries');
      print('Experience: ${experienceList.length} entries');
      print('Projects: ${projectsList.length} entries');
      print('Certifications: ${certificationsList.length} entries');

      // ═══════════════════════════════════════════════════════════════
      // 4. CALL FLASK API
      // ═══════════════════════════════════════════════════════════════

      final uri = Uri.parse('http://192.168.0.102:5000/generate-resume');

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw Exception('Request timed out - server may be processing');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save PDF locally
        final pdfBytes = base64Decode(data['pdf_base64'] as String);
        final dir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filePath =
            '${dir.path}/resume_${careerTitle.replaceAll(' ', '_')}_$timestamp.pdf';
        final file = File(filePath);
        await file.writeAsBytes(pdfBytes);

        print('✓ Resume generated successfully');
        print('✓ PDF saved to: $filePath');

        setState(() {
          _resumeResult = data;
          _pdfFilePath = filePath;
          _isLoading = false;
        });
      } else {
        throw Exception(
          'Server error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e, stack) {
      print('✗ Resume generation failed');
      print('Error: $e');
      print('Stack: $stack');

      setState(() {
        _errorMessage =
            'Failed to generate resume.\n\n'
            'Error: ${e.toString()}\n\n'
            'Please check:\n'
            '• Your internet connection\n'
            '• Flask server is running\n'
            '• API endpoint is correct';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ═══════════════════════════════════════════════════════════════
    // LOADING STATE
    // ═══════════════════════════════════════════════════════════════
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Resume for $careerTitle'),
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Generating your professional resume...',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'This may take 10-30 seconds',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    // ═══════════════════════════════════════════════════════════════
    // ERROR STATE
    // ═══════════════════════════════════════════════════════════════
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Resume for $careerTitle'),
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 24),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _generateResume();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ═══════════════════════════════════════════════════════════════
    // SUCCESS STATE
    // ═══════════════════════════════════════════════════════════════
    final good =
        _resumeResult?['good'] ??
        'Your resume shows promise and good foundational skills.';
    final needs =
        _resumeResult?['needs_improvement'] ??
        'Consider adding more quantifiable achievements and specific project details.';
    final score = (_resumeResult?['readiness_score'] as num?)?.toInt() ?? 70;

    return Scaffold(
      appBar: AppBar(
        title: Text('Resume for $careerTitle'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ═══════════════════════════════════════════════════════════
          // EVALUATION CARD
          // ═══════════════════════════════════════════════════════════
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resume Readiness Evaluation',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Readiness Score: ',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '$score/100',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: score >= 80
                              ? Colors.green
                              : score >= 60
                              ? Colors.orange
                              : Colors.red,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        score >= 80
                            ? Icons.check_circle
                            : score >= 60
                            ? Icons.trending_up
                            : Icons.info_outline,
                        color: score >= 80
                            ? Colors.green
                            : score >= 60
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text(
                    '✓ Strengths:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(good, style: const TextStyle(height: 1.4)),
                  const SizedBox(height: 16),
                  const Text(
                    '→ Areas to Improve:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    needs,
                    style: const TextStyle(
                      height: 1.4,
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ═══════════════════════════════════════════════════════════
          // PDF PREVIEW
          // ═══════════════════════════════════════════════════════════
          if (_pdfFilePath != null)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.description, color: Color(0xFF2563EB)),
                        SizedBox(width: 8),
                        Text(
                          'Generated Resume Preview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 500,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                      child: SfPdfViewer.file(
                        File(_pdfFilePath!),
                        enableDoubleTapZooming: true,
                        enableDocumentLinkAnnotation: true,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.file_download),
                            label: const Text('Open PDF'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () async {
                              final result = await OpenFile.open(_pdfFilePath);
                              if (result.type != ResultType.done) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Could not open file: ${result.message}',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.share),
                            label: const Text('Share'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              // TODO: Implement share functionality
                              // Use share_plus package: Share.shareFiles([_pdfFilePath!])
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Share feature coming soon!'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No PDF generated yet',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
