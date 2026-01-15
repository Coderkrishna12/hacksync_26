// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:hacksync_26/signin.dart';

// class SignupPage extends StatefulWidget {
//   const SignupPage({super.key});

//   @override
//   State<SignupPage> createState() => _SignupPageState();
// }

// class _SignupPageState extends State<SignupPage> {
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _isLoading = false;
//   String? _errorMessage;

//   final Color primaryBlue = const Color(0xFF2563EB);
//   final Color bgGray = const Color(0xFFF8FAFC);
//   final Color textDark = const Color(0xFF1E293B);
//   final Color slateDark = const Color(0xFF64748B);
//   final Color slateLight = const Color(0xFFF1F5F9);
//   final Color slateMedium = const Color(0xFFCBD5E1);

//   // ────────────────────────────────────────────────
//   // ──  Logic remains 100% unchanged              ──
//   // ────────────────────────────────────────────────

//   Future<void> _signup() async {
//     setState(() {
//       _errorMessage = null;
//       _isLoading = true;
//     });

//     final name = _nameController.text.trim();
//     final email = _emailController.text.trim();
//     final password = _passwordController.text.trim();

//     if (name.isEmpty) {
//       _showError('Please enter your full name');
//       return;
//     }

//     if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
//       _showError('Please enter a valid email address');
//       return;
//     }

//     if (password.isEmpty || password.length < 6) {
//       _showError('Password must be at least 6 characters');
//       return;
//     }

//     try {
//       await FirebaseAuth.instance.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//     } on FirebaseAuthException catch (e) {
//       _showError(_friendlyErrorMessage(e.code) ?? e.message ?? 'Registration failed');
//     } catch (_) {
//       _showError('Something went wrong. Please check your connection.');
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   void _showError(String message) {
//     setState(() {
//       _errorMessage = message;
//       _isLoading = false;
//     });
//   }

//   String? _friendlyErrorMessage(String code) {
//     switch (code) {
//       case 'email-already-in-use': return 'This email is already registered.';
//       case 'weak-password': return 'Password is too weak.';
//       default: return null;
//     }
//   }

//   // ────────────────────────────────────────────────
//   // ──        Consistent Minimalist UI             ──
//   // ────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: primaryBlue.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Icon(Icons.person_add_rounded, size: 36, color: primaryBlue),
//                 ),
//                 const SizedBox(height: 32),

//                 Text(
//                   'Create Account',
//                   style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: textDark, letterSpacing: -0.5),
//                 ),
//                 const SizedBox(height: 8),
//                 Text('Join ConnectSphere today.', style: TextStyle(fontSize: 16, color: slateDark)),

//                 const SizedBox(height: 40),

//                 _buildLabel("Full Name"),
//                 _buildMinimalTextField(controller: _nameController, hint: "John Doe", icon: Icons.person_outline),

//                 const SizedBox(height: 20),

//                 _buildLabel("Email Address"),
//                 _buildMinimalTextField(controller: _emailController, hint: "name@example.com", icon: Icons.alternate_email_rounded, keyboardType: TextInputType.emailAddress),

//                 const SizedBox(height: 20),

//                 _buildLabel("Password"),
//                 _buildMinimalTextField(controller: _passwordController, hint: "Min. 6 characters", icon: Icons.lock_outline_rounded, obscureText: true),

//                 if (_errorMessage != null)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 16),
//                     child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500)),
//                   ),

//                 const SizedBox(height: 40),

//                 SizedBox(
//                   width: double.infinity,
//                   height: 56,
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : _signup,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: primaryBlue,
//                       foregroundColor: Colors.white,
//                       elevation: 0,
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                     ),
//                     child: _isLoading
//                         ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
//                         : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
//                   ),
//                 ),

//                 const SizedBox(height: 32),

//                 Center(
//                   child: TextButton(
//                     onPressed: () {
//                       Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
//                     },
//                     child: RichText(
//                       text: TextSpan(
//                         style: TextStyle(color: slateDark, fontSize: 14),
//                         children: [
//                           const TextSpan(text: "Have an account? "),
//                           TextSpan(text: 'Sign in', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildLabel(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8, left: 4),
//       child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDark)),
//     );
//   }

//   Widget _buildMinimalTextField({
//     required TextEditingController controller,
//     required String hint,
//     required IconData icon,
//     bool obscureText = false,
//     TextInputType? keyboardType,
//   }) {
//     return TextField(
//       controller: controller,
//       obscureText: obscureText,
//       keyboardType: keyboardType,
//       style: TextStyle(color: textDark, fontWeight: FontWeight.w500),
//       decoration: InputDecoration(
//         hintText: hint,
//         hintStyle: TextStyle(color: slateMedium, fontSize: 15),
//         prefixIcon: Icon(icon, color: slateMedium, size: 20),
//         filled: true,
//         fillColor: bgGray,
//         contentPadding: const EdgeInsets.symmetric(vertical: 18),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
//         enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: slateLight)),
//         focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryBlue, width: 1.5)),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ← Added this
import 'package:hacksync_26/signin.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  final Color primaryBlue = const Color(0xFF2563EB);
  final Color bgGray = const Color(0xFFF8FAFC);
  final Color textDark = const Color(0xFF1E293B);
  final Color slateDark = const Color(0xFF64748B);
  final Color slateLight = const Color(0xFFF1F5F9);
  final Color slateMedium = const Color(0xFFCBD5E1);

  Future<void> _signup() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty) {
      _showError('Please enter your full name');
      return;
    }

    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showError('Please enter a valid email address');
      return;
    }

    if (password.isEmpty || password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    try {
      // Create user in Firebase Auth (user will be automatically signed in)
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Store additional data (name, email, timestamp) in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
            'name': name,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
            'uid': credential.user!.uid,
          });

      // Optional: Navigate to your home/dashboard screen here
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    } on FirebaseAuthException catch (e) {
      _showError(
        _friendlyErrorMessage(e.code) ?? e.message ?? 'Registration failed',
      );
    } catch (e) {
      _showError('Something went wrong. Please check your connection.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  String? _friendlyErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email format.';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.person_add_rounded,
                    size: 36,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join ConnectSphere today.',
                  style: TextStyle(fontSize: 16, color: slateDark),
                ),

                const SizedBox(height: 40),

                _buildLabel("Full Name"),
                _buildMinimalTextField(
                  controller: _nameController,
                  hint: "John Doe",
                  icon: Icons.person_outline,
                ),

                const SizedBox(height: 20),

                _buildLabel("Email Address"),
                _buildMinimalTextField(
                  controller: _emailController,
                  hint: "name@example.com",
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 20),

                _buildLabel("Password"),
                _buildMinimalTextField(
                  controller: _passwordController,
                  hint: "Min. 6 characters",
                  icon: Icons.lock_outline_rounded,
                  obscureText: true,
                ),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 32),

                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: slateDark, fontSize: 14),
                        children: [
                          const TextSpan(text: "Have an account? "),
                          TextSpan(
                            text: 'Sign in',
                            style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
      ),
    );
  }

  Widget _buildMinimalTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: textDark, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: slateMedium, fontSize: 15),
        prefixIcon: Icon(icon, color: slateMedium, size: 20),
        filled: true,
        fillColor: bgGray,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: slateLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue, width: 1.5),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
