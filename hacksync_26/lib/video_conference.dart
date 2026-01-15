import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';

class QuickMeetingScreen extends StatefulWidget {
  const QuickMeetingScreen({super.key});

  @override
  State<QuickMeetingScreen> createState() => _QuickMeetingScreenState();
}

class _QuickMeetingScreenState extends State<QuickMeetingScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isCreating = false;
  String? _generatedLink;
  String? _roomName;
  String? _token;

  // LiveKit config (keep secret in production – use env/backend)
  static const String _apiKey = 'API3NwTjX3rnPz2';
  static const String _apiSecret =
      'L8eEOQdG4gKAfi2zi2Qm9eJCkZChw0dh7iBDecw6xcKA';
  static const String _livekitUrl = 'wss://fitsync-yykk3win.livekit.cloud';

  final ThemeData _theme = ThemeData(
    primaryColor: const Color(0xFF1DB954),
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF1DB954),
      secondary: Color(0xFF1ED760),
      surface: Color(0xFF282828),
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      elevation: 0,
      centerTitle: true,
    ),
  );

  Future<void> _createAndShareMeeting() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please sign in first")));
      return;
    }

    setState(() => _isCreating = true);

    try {
      final roomName = 'meeting_${const Uuid().v4().substring(0, 12)}';
      final identity = 'user_${user.uid.substring(0, 8)}';

      final jwt = JWT({
        'video': {
          'roomJoin': true,
          'room': roomName,
          'roomAdmin': true,
          'canPublish': true,
          'canSubscribe': true,
        },
        'sub': identity,
        'name': identity,
        'exp':
            DateTime.now()
                .add(const Duration(hours: 24))
                .millisecondsSinceEpoch ~/
            1000,
      }, issuer: _apiKey);

      final token = jwt.sign(
        SecretKey(_apiSecret),
        algorithm: JWTAlgorithm.HS256,
      );
      final link = '$_livekitUrl?room=$roomName&token=$token';

      // Save to Firestore (visible to others if you query this collection)
      await _firestore.collection('quick_meetings').add({
        'creatorId': user.uid,
        'roomName': roomName,
        'token': token, // optional – avoid long-term for security
        'link': link,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromMillisecondsSinceEpoch(
          DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch,
        ),
      });

      setState(() {
        _roomName = roomName;
        _token = token;
        _generatedLink = link;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Meeting link ready!"),
          backgroundColor: _theme.colorScheme.secondary,
        ),
      );

      // Show dialog with copy-friendly info
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF282828),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Your Meeting Link",
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  "Room: $roomName",
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  "Full Link:\n$link",
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "To join:\n"
                  "1. Go to https://meet.livekit.io\n"
                  "2. Use 'Custom' tab → enter server: $_livekitUrl\n"
                  "3. Paste Room name & Token\n"
                  "Or integrate in your app with LiveKit SDK.",
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Close",
                style: TextStyle(color: _theme.primaryColor),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _theme,
      child: Scaffold(
        appBar: AppBar(title: const Text("Quick Meeting")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.video_call_rounded,
                  size: 100,
                  color: _theme.primaryColor.withOpacity(0.9),
                ),
                const SizedBox(height: 32),
                const Text(
                  "Create Instant Meeting",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  "One tap to generate a shareable LiveKit link",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isCreating ? null : _createAndShareMeeting,
                    icon: _isCreating
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.black54,
                            ),
                          )
                        : const Icon(Icons.videocam),
                    label: Text(
                      _isCreating ? "Creating..." : "Generate Link",
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _theme.primaryColor,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (_generatedLink != null) ...[
                  const SizedBox(height: 40),
                  const Text(
                    "Last generated link (copy from dialog)",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
