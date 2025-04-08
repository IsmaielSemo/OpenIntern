import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _universityController = TextEditingController();

  DateTime? _dateOfBirth;
  int? _graduationYear;
  final List<int> _graduationYears = List.generate(
    10,
    (index) => DateTime.now().year + index - 4,
  );

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _emailError;
  String? _usernameError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _dobError;
  String? _universityError;
  String? _graduationYearError;

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _universityController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(DateTime.now().year - 18),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4285F4),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
        _dobError = null;
      });
    }
  }

  Future<void> _attemptSignup() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully!')),
      );
    }
  }

  bool _validateForm() {
    setState(() {
      _emailError = null;
      _usernameError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _dobError = null;
      _universityError = null;
      _graduationYearError = null;
    });

    bool isValid = true;

    // Validate email
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _emailError = 'Email cannot be empty';
      });
      isValid = false;
    } else if (!_validateEmail(email)) {
      setState(() {
        _emailError = 'Please enter a valid email address';
      });
      isValid = false;
    }

    // Validate username
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() {
        _usernameError = 'Username cannot be empty';
      });
      isValid = false;
    } else if (!_validateUsername(username)) {
      isValid = false;
    }

    // Validate password
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() {
        _passwordError = 'Password cannot be empty';
      });
      isValid = false;
    } else if (!_validatePassword(password)) {
      isValid = false;
    }

    // Validate confirm password
    final confirmPassword = _confirmPasswordController.text;
    if (confirmPassword.isEmpty) {
      setState(() {
        _confirmPasswordError = 'Please confirm your password';
      });
      isValid = false;
    } else if (password != confirmPassword) {
      setState(() {
        _confirmPasswordError = 'Passwords do not match';
      });
      isValid = false;
    }

    // Validate date of birth
    if (!_validateDateOfBirth()) {
      isValid = false;
    }

    // Validate university
    final university = _universityController.text.trim();
    if (university.isEmpty) {
      setState(() {
        _universityError = 'Please enter your university';
      });
      isValid = false;
    }

    // Validate graduation year
    if (_graduationYear == null) {
      setState(() {
        _graduationYearError = 'Please select your graduation year';
      });
      isValid = false;
    }

    return isValid;
  }

  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _validateUsername(String username) {
    if (username.length < 3) {
      _usernameError = 'Username must be at least 3 characters long';
      return false;
    }
    return true;
  }

  bool _validatePassword(String password) {
    if (password.length < 8) {
      _passwordError = 'Password must be at least 8 characters long';
      return false;
    }
    if (RegExp(r'^[0-9]').hasMatch(password)) {
      _passwordError = 'Password must not start with a number';
      return false;
    }
    if (!RegExp(r'[a-zA-Z]').hasMatch(password)) {
      _passwordError = 'Password must contain letters';
      return false;
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      _passwordError = 'Password must contain numbers';
      return false;
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      _passwordError = 'Password must contain special characters';
      return false;
    }
    return true;
  }

  bool _validateDateOfBirth() {
    if (_dateOfBirth == null) {
      _dobError = 'Please select your date of birth';
      return false;
    }

    final today = DateTime.now();
    final sixteenYearsAgo = DateTime(
      today.year - 16,
      today.month,
      today.day,
    );

    if (_dateOfBirth!.isAfter(sixteenYearsAgo)) {
      _dobError = 'You must be at least 16 years old to register';
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -50,
            left: -100,
            child: _buildBlueCurve(),
          ),
          Positioned(
            bottom: -50,
            right: -100,
            child: _buildBlueCurve(),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Color(0xFF4285F4)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4285F4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Email'),
                          _buildTextField(
                            controller: _emailController,
                            hintText: 'your.email@example.com',
                            errorText: _emailError,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),
                          _buildFieldLabel('Username'),
                          _buildTextField(
                            controller: _usernameController,
                            hintText: 'username (min. 3 characters)',
                            errorText: _usernameError,
                          ),
                          const SizedBox(height: 20),
                          _buildFieldLabel('Password'),
                          _buildTextField(
                            controller: _passwordController,
                            hintText: '••••••••',
                            errorText: _passwordError,
                            obscureText: _obscurePassword,
                            toggleObscure: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          _buildHelpText(
                            'Password must be at least 8 characters, not start with a number, '
                            'and contain letters, numbers, and special characters.',
                          ),
                          const SizedBox(height: 20),
                          _buildFieldLabel('Confirm Password'),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            hintText: '••••••••',
                            errorText: _confirmPasswordError,
                            obscureText: _obscureConfirmPassword,
                            toggleObscure: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildFieldLabel('Date of Birth'),
                          GestureDetector(
                            onTap: _selectDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    _dateOfBirth != null
                                        ? intl.DateFormat('MMM dd, yyyy')
                                            .format(_dateOfBirth!)
                                        : 'Select your date of birth',
                                    style: TextStyle(
                                      color: _dateOfBirth != null
                                          ? Colors.black
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.calendar_today,
                                      color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                          if (_dobError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 16),
                              child: Text(
                                _dobError!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          _buildHelpText('You must be at least 16 years old'),
                          const SizedBox(height: 20),
                          _buildFieldLabel('University'),
                          _buildTextField(
                            controller: _universityController,
                            hintText: 'Your university name',
                            errorText: _universityError,
                          ),
                          const SizedBox(height: 20),
                          _buildFieldLabel('Graduation Year'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonFormField<int>(
                              value: _graduationYear,
                              hint: const Text('Select graduation year'),
                              isExpanded: true,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 10),
                              ),
                              items: _graduationYears.map((int year) {
                                return DropdownMenuItem<int>(
                                  value: year,
                                  child: Text(year.toString()),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _graduationYear = value;
                                  _graduationYearError = null;
                                });
                              },
                            ),
                          ),
                          if (_graduationYearError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 16),
                              child: Text(
                                _graduationYearError!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _attemptSignup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4285F4),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                disabledBackgroundColor:
                                    const Color(0xFF4285F4).withOpacity(0.5),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Sign Up',
                                      style: TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacementNamed(
                                        context, '/login');
                                  },
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                      color: Color(0xFF4285F4),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.grey[800],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? errorText,
    bool obscureText = false,
    VoidCallback? toggleObscure,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        errorText: errorText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: toggleObscure,
              )
            : null,
      ),
    );
  }

  Widget _buildHelpText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 16),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildBlueCurve() {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFF4285F4).withOpacity(0.3),
        borderRadius: BorderRadius.circular(150),
      ),
    );
  }
}
