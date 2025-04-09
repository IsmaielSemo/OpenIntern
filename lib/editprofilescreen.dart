import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'validators.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _universityController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  int? _graduationYear;
  final List<int> _graduationYears = List.generate(
    10,
        (index) => DateTime.now().year + index - 4,
  );
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _usernameError;
  String? _universityError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _graduationYearError;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordChangeRequested = false;
  bool _isProfileLoading = true;
  Map<String, dynamic>? _userProfile;

  // Track which fields have been modified
  bool _usernameModified = false;
  bool _universityModified = false;
  bool _graduationYearModified = false;

  // API base URL
  final String apiUrl = 'http://10.65.150.71:3000';

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _universityController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      _isProfileLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$apiUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _userProfile = data;
          _usernameController.text = data['username'] ?? '';
          _universityController.text = data['university'] ?? '';
          _graduationYear = data['graduation_year'];
          _isProfileLoading = false;
        });

        // Add listeners to track modifications
        _usernameController.addListener(() {
          if (_usernameController.text != _userProfile?['username']) {
            setState(() {
              _usernameModified = true;
            });
          } else {
            setState(() {
              _usernameModified = false;
            });
          }
        });

        _universityController.addListener(() {
          if (_universityController.text != _userProfile?['university']) {
            setState(() {
              _universityModified = true;
            });
          } else {
            setState(() {
              _universityModified = false;
            });
          }
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load profile';
          _isProfileLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: ${e.toString()}';
        _isProfileLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_validateForm()) return;

    // Check if any changes were made
    if (!_usernameModified && !_universityModified && !_graduationYearModified && !_isPasswordChangeRequested) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes were made')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Map<String, dynamic> updateData = {};

      // Only include fields that were modified
      if (_usernameModified) {
        updateData['username'] = _usernameController.text.trim();
      }

      if (_universityModified) {
        updateData['university'] = _universityController.text.trim();
      }

      if (_graduationYearModified) {
        updateData['graduationYear'] = _graduationYear;
      }

      // Only include password if the user wants to change it
      if (_isPasswordChangeRequested) {
        updateData['password'] = _passwordController.text;
      }

      final response = await http.put(
        Uri.parse('$apiUrl/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Failed to update profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  bool _validateForm() {
    setState(() {
      _usernameError = null;
      _universityError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _graduationYearError = null;
    });

    bool isValid = true;

    // Only validate fields that have been modified
    if (_usernameModified) {
      final username = _usernameController.text.trim();
      if (username.isEmpty) {
        setState(() {
          _usernameError = 'Username cannot be empty';
        });
        isValid = false;
      } else if (username.length < 3) {
        setState(() {
          _usernameError = 'Username must be at least 3 characters long';
        });
        isValid = false;
      }
    }

    if (_universityModified) {
      final university = _universityController.text.trim();
      if (university.isEmpty) {
        setState(() {
          _universityError = 'Please enter your university';
        });
        isValid = false;
      }
    }

    // Validate password if change is requested
    if (_isPasswordChangeRequested) {
      final password = _passwordController.text;
      final passwordError = Validators.validatePassword(password);
      if (passwordError != null) {
        setState(() {
          _passwordError = passwordError;
        });
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
    }

    // Validate graduation year if modified
    if (_graduationYearModified && _graduationYear == null) {
      setState(() {
        _graduationYearError = 'Please select your graduation year';
      });
      isValid = false;
    }

    return isValid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFF4285F4),
      ),
      body: _isProfileLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFF4285F4),
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _buildFieldLabel('Username'),
              _buildTextField(
                controller: _usernameController,
                hintText: 'Enter username',
                errorText: _usernameError,
                isModified: _usernameModified,
              ),
              const SizedBox(height: 20),
              _buildFieldLabel('University'),
              _buildTextField(
                controller: _universityController,
                hintText: 'Enter university',
                errorText: _universityError,
                isModified: _universityModified,
              ),
              const SizedBox(height: 20),
              _buildFieldLabel('Graduation Year'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: _graduationYearModified
                      ? Border.all(color: const Color(0xFF4285F4), width: 2)
                      : null,
                ),
                child: DropdownButtonFormField<int>(
                  value: _graduationYear,
                  hint: const Text('Select graduation year'),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
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
                      _graduationYearModified = value != _userProfile?['graduation_year'];
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
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Change Password'),
                value: _isPasswordChangeRequested,
                activeColor: const Color(0xFF4285F4),
                onChanged: (value) {
                  setState(() {
                    _isPasswordChangeRequested = value;
                    if (!value) {
                      _passwordController.clear();
                      _confirmPasswordController.clear();
                      _passwordError = null;
                      _confirmPasswordError = null;
                    }
                  });
                },
              ),
              if (_isPasswordChangeRequested) ...[
                const SizedBox(height: 10),
                _buildFieldLabel('New Password'),
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
                  isModified: true,
                ),
                _buildHelpText(
                  'Password must be at least 8 characters, not start with a number, '
                      'and contain letters, numbers, and special characters.',
                ),
                const SizedBox(height: 20),
                _buildFieldLabel('Confirm New Password'),
                _buildTextField(
                  controller: _confirmPasswordController,
                  hintText: '••••••••',
                  errorText: _confirmPasswordError,
                  obscureText: _obscureConfirmPassword,
                  toggleObscure: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  isModified: true,
                ),
              ],
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4285F4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    disabledBackgroundColor: const Color(0xFF4285F4).withOpacity(0.5),
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
                    'Save Changes',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
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
    bool isModified = false,
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
          borderSide: isModified
              ? const BorderSide(color: Color(0xFF4285F4), width: 2)
              : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: isModified
              ? const BorderSide(color: Color(0xFF4285F4), width: 2)
              : BorderSide.none,
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
}
