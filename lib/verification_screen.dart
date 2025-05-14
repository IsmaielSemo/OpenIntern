import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'welcome_screen.dart';
import 'homescreen.dart';
import 'profile_setup_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  final bool isDeactivation;

  const VerificationScreen({
    super.key,
    required this.email,
    this.isDeactivation = false,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final auth = FirebaseAuth.instance;
  late User user;
  late Timer timer;
  bool isEmailVerified = false;
  String _error = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    user = auth.currentUser!;
    checkEmailVerification();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  Future<void> checkEmailVerification() async {
    // Start checking email verification status every 3 seconds
    timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkVerificationStatus(),
    );
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user is currently logged in');
      }

      await user.reload();
      if (user.emailVerified) {
        if (!mounted) return;
        if (widget.isDeactivation) {
          // Delete user from Firestore and Auth
          await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
          await user.delete();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            (route) => false,
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileSetupScreen(),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _resendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user is currently logged in');
      await user.reload();
      if (user.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your email is already verified.')),
        );
        return;
      }
      await user.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email resent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isDeactivation ? 'Verify Deactivation' : 'Email Verification'),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF4285F4),
              const Color(0xFF4285F4).withOpacity(0.8),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isDeactivation ? Icons.warning_amber_rounded : Icons.email_outlined,
                      size: 80,
                      color: widget.isDeactivation ? Colors.red : const Color(0xFF4285F4),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isEmailVerified
                          ? widget.isDeactivation
                              ? 'Account Deactivated'
                              : 'Email Verified!'
                          : widget.isDeactivation
                              ? 'Verify Deactivation'
                              : 'Verify your email',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEmailVerified
                          ? widget.isDeactivation
                              ? 'Your account has been successfully deactivated.'
                              : 'Your email has been successfully verified. You can now login to your account.'
                          : widget.isDeactivation
                              ? 'We\'ve sent a verification link to ${widget.email}. Please check your inbox and click the link to verify your identity and deactivate your account.'
                              : 'We\'ve sent a verification link to ${widget.email}. Please check your inbox and click the link to verify your email address.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (isEmailVerified)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4285F4),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            if (widget.isDeactivation) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                                (route) => false,
                              );
                            } else {
                              Navigator.of(context).pop();
                            }
                          },
                          child: Text(
                            widget.isDeactivation ? 'Return to Welcome' : 'Continue to Login',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4285F4),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _isLoading ? null : _resendVerificationEmail,
                              child: const Text(
                                'Resend Email',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}