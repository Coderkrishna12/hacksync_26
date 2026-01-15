// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter_pdfview/flutter_pdfview.dart'; // add dependency: pdf_viewer or flutter_pdfview

// class ResumePreviewScreen extends StatefulWidget {
//   final Map<String, dynamic> career;

//   const ResumePreviewScreen({super.key, required this.career});

//   @override
//   State<ResumePreviewScreen> createState() => _ResumePreviewScreenState();
// }

// class _ResumePreviewScreenState extends State<ResumePreviewScreen> {
//   bool _isLoading = true;
//   String? _error;
//   Map<String, dynamic>? _resumeData;
//   String? _pdfBase64;
//   String? _errorMessage;
//   late String careerTitle;
//   Map<String, dynamic>? _resumeResult;

//   @override
//   void initState() {
//     super.initState();
//     _generateResume();
//   }

//   Future<void> _generateResume() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       setState(() {
//         _errorMessage = "You must be signed in to generate a resume.";
//         _isLoading = false;
//       });
//       return;
//     }

//     try {
//       // ── 1. Fetch profile document ────────────────────────────────────────
//       final profileSnap = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .collection('profile')
//           .doc('details')
//           .get();

//       // ── 2. Fetch skills document ─────────────────────────────────────────
//       final skillsSnap = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .collection('skills')
//           .doc('profile_skills')
//           .get();

//       // ── Safe defaults / placeholders ─────────────────────────────────────
//       String name = user.displayName ?? 'Your Name';
//       String email = user.email ?? 'your.email@example.com';
//       String phone = 'Not provided';
//       String bio =
//           'Aspiring professional seeking opportunities in ${careerTitle.toLowerCase()}.';
//       String education = 'Not specified';
//       List<String> userSkills = [];

//       // ── Profile document (if exists) ─────────────────────────────────────
//       if (profileSnap.exists) {
//         final pData = profileSnap.data()!;
//         name = pData['name'] as String? ?? name;
//         phone = pData['phone'] as String? ?? phone;
//         bio = (pData['bio'] as String? ?? pData['about'] as String? ?? bio);
//       }

//       // ── Skills document (if exists) ──────────────────────────────────────
//       if (skillsSnap.exists) {
//         final sData = skillsSnap.data()!;
//         userSkills = List<String>.from(sData['top_skills'] ?? []);
//         education = sData['education'] as String? ?? education;
//       }

//       // ── Final fallback for education (if still missing) ──────────────────
//       if (education == 'Not specified') {
//         education = 'Bachelor'; // or whatever default makes sense for your app
//       }

//       // ── Build payload with whatever we have ──────────────────────────────
//       final payload = {
//         'user_info': {
//           'name': name,
//           'email': email,
//           'phone': phone,
//           'education': education,
//           'bio': bio,
//           'skills': userSkills,
//         },
//         'career': careerTitle,
//         'job_description':
//             widget.career['next_steps'] ??
//             widget.career['career_path'] ??
//             'Entry-level role in $careerTitle',
//         'matched_skills': widget.career['matched_skills'] ?? [],
//         'missing_skills': widget.career['missing_skills'] ?? [],
//       };

//       // ── Call the API ─────────────────────────────────────────────────────
//       final uri = Uri.parse('http://10.0.2.2:5000/generate-resume');

//       final response = await http.post(
//         uri,
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode(payload),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         setState(() {
//           _resumeResult = data;
//           _pdfBase64 = data['pdf_base64'];
//           _isLoading = false;
//         });
//       } else {
//         setState(() {
//           _errorMessage =
//               "Server error ${response.statusCode}\n${response.body}";
//           _isLoading = false;
//         });
//       }
//     } catch (e, stack) {
//       print("Resume generation failed: $e");
//       print("Stack: $stack");
//       setState(() {
//         _errorMessage = "Failed to generate resume.\n$e";
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }

//     if (_error != null) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Resume Builder')),
//         body: Center(
//           child: Text(_error!, style: const TextStyle(color: Colors.red)),
//         ),
//       );
//     }

//     final good = _resumeData?['good'] ?? '';
//     final needs = _resumeData?['needs_improvement'] ?? '';
//     final score = _resumeData?['readiness_score'] ?? '?';

//     return Scaffold(
//       appBar: AppBar(title: const Text('Resume Preview')),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Evaluation for ${widget.career['career']}',
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       'Readiness Score: $score/100',
//                       style: const TextStyle(fontSize: 16, color: Colors.blue),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Good: $good',
//                       style: const TextStyle(color: Colors.green),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Needs Improvement: $needs',
//                       style: const TextStyle(color: Colors.orange),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 24),
//             if (_pdfBase64 != null)
//               ElevatedButton.icon(
//                 onPressed: () {
//                   // Show PDF viewer or download
//                   // Example: use flutter_pdfview or share base64
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text(
//                         'PDF ready — implement viewer/download here',
//                       ),
//                     ),
//                   );
//                 },
//                 icon: const Icon(Icons.picture_as_pdf),
//                 label: const Text('View / Download PDF'),
//                 style: ElevatedButton.styleFrom(
//                   minimumSize: const Size.fromHeight(54),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

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
      // Fetch profile (safe)
      final profileSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('details')
          .get();

      // Fetch skills (safe)
      final skillsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('skills')
          .doc('profile_skills')
          .get();

      // Safe defaults
      String name = user.displayName ?? 'Amit';
      String email = user.email ?? 'amit@example.com';
      String phone = 'Not provided';
      String bio =
          'Motivated professional passionate about ${careerTitle.toLowerCase()}. '
          'Eager to contribute strong technical skills and a growth mindset.';
      String education = 'Bachelor’s Degree';
      List<String> userSkills = [
        'Flutter',
        'React Js',
        'Next.js',
        'Python',
        'Machine Learning',
      ]; // fallback

      if (profileSnap.exists) {
        final data = profileSnap.data()!;
        name = data['name'] as String? ?? name;
        phone = data['phone'] as String? ?? phone;
        bio = data['bio'] as String? ?? data['about'] as String? ?? bio;
      }

      if (skillsSnap.exists) {
        final data = skillsSnap.data()!;
        userSkills = List<String>.from(data['top_skills'] ?? userSkills);
        education = data['education'] as String? ?? education;
      }

      // Prepare payload
      final payload = {
        'user_info': {
          'name': name,
          'email': email,
          'phone': phone,
          'education': education,
          'bio': bio,
          'skills': userSkills,
        },
        'career': careerTitle,
        'job_description':
            widget.career['next_steps'] ??
            widget.career['career_path'] ??
            'Entry-level role in $careerTitle. Focus on building strong foundations and learning in-demand skills.',
        'matched_skills': widget.career['matched_skills'] ?? [],
        'missing_skills': widget.career['missing_skills'] ?? [],
      };

      // Call Flask
      final uri = Uri.parse(
        'http://192.168.0.102:5000/generate-resume',
      ); // ← change if needed

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save PDF locally
        final pdfBytes = base64Decode(data['pdf_base64'] as String);
        final dir = await getTemporaryDirectory();
        final filePath =
            '${dir.path}/resume_${careerTitle.replaceAll(' ', '_')}.pdf';
        final file = File(filePath);
        await file.writeAsBytes(pdfBytes);

        setState(() {
          _resumeResult = data;
          _pdfFilePath = filePath;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              "Server responded with error:\n${response.statusCode} - ${response.body}";
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      print("Resume error: $e\n$stack");
      setState(() {
        _errorMessage = "Failed to generate resume.\n$e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Resume for $careerTitle')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Resume for $careerTitle')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final good =
        _resumeResult?['good'] ?? 'No detailed evaluation available yet.';
    final needs =
        _resumeResult?['needs_improvement'] ??
        'Consider adding more projects and quantifiable achievements.';
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
          // Evaluation Card
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
                  Text(
                    'Resume Readiness Evaluation',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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
                    ],
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Strengths:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  Text(good, style: const TextStyle(height: 1.4)),
                  const SizedBox(height: 16),
                  const Text(
                    'Areas to Improve:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
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

          // PDF Preview
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
                    child: Text(
                      'Generated Resume Preview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.download),
                            label: const Text('Download'),
                            onPressed: () async {
                              final result = await OpenFile.open(_pdfFilePath);
                              if (result.type != ResultType.done) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Open failed: ${result.message}',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.share),
                            label: const Text('Share'),
                            onPressed: () {
                              // Add share logic later (e.g. share_plus package)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Share feature coming soon'),
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
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'No PDF generated yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
