import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'profile_setup_screen.dart';
import 'welcome_screen.dart';

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
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _formKey = GlobalKey<FormState>();
  bool _isVerifying = false;
  bool _isVerified = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onCodeChanged(String value, int index) {
    if (value.length == 1) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      }
    }
  }

  String get _verificationCode {
    return _controllers.map((c) => c.text).join();
  }

  Future<void> _verifyCode() async {
    if (_verificationCode.length == 6) {
      setState(() {
        _isVerifying = true;
      });

      // Simulate verification delay
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isVerified = true;
      });

      // Wait a moment to show the success state
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        if (widget.isDeactivation) {
          // For deactivation, go back to welcome screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            (route) => false,
          );
        } else {
          // For email verification, go to profile setup
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileSetupScreen(),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.isDeactivation
                              ? 'Verify Deactivation'
                              : 'Verify Your Email',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.isDeactivation
                              ? 'Please enter the verification code to confirm account deactivation'
                              : 'We\'ve sent a verification code to ${widget.email}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(6, (index) {
                            return SizedBox(
                              width: 45,
                              child: TextField(
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                maxLength: 1,
                                enabled: !_isVerifying,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (value) => _onCodeChanged(value, index),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 24),
                        if (_isVerified)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                widget.isDeactivation
                                    ? Icons.check_circle
                                    : Icons.check_circle,
                                color: widget.isDeactivation ? Colors.red : Colors.green,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.isDeactivation
                                    ? 'Account Deactivated'
                                    : 'Verified!',
                                style: TextStyle(
                                  color: widget.isDeactivation ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.isDeactivation
                                    ? Colors.red
                                    : const Color(0xFF4285F4),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _isVerifying ? null : _verifyCode,
                              child: _isVerifying
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      widget.isDeactivation ? 'Deactivate' : 'Verify',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 