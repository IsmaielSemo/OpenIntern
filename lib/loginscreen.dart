import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;
  bool _isLoading = false;
  String? _errorMessage;

  // API base URL - replace with your actual server URL
  final String apiUrl = 'http://10.65.150.71:3000';
  // Use 'http://localhost:3000' for web or 'http://127.0.0.1:3000' for iOS simulator

  // Auth0 credentials - replace with your own
  final String domain = 'dev-1uzu6bsvrd2mj3og.us.auth0.com';
  final String clientId = 'CZHJxAwp7QDLyavDaTLRzoy9yLKea4A1';
  final String redirectUri = 'com.openintern.app://login-callback';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth0Login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String authUrl = 'https://$domain/authorize'
          '?client_id=$clientId'
          '&redirect_uri=$redirectUri'
          '&response_type=code'
          '&scope=openid%20profile%20email';

      final result = await FlutterWebAuth.authenticate(
        url: authUrl,
        callbackUrlScheme: redirectUri.split('://')[0],
      );

      final code = Uri.parse(result).queryParameters['code'];
      if (code != null) {
        final user = await _exchangeToken(code);
        await _handleUserRegistration(user);
      } else {
        setState(() {
          _errorMessage = 'Failed to authenticate';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _exchangeToken(String code) async {
    final tokenEndpoint = 'https://$domain/oauth/token';
    try {
      final response = await http.post(
        Uri.parse(tokenEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'grant_type': 'authorization_code',
          'client_id': clientId,
          'code': code,
          'redirect_uri': redirectUri,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Token exchange failed');
      }

      final data = jsonDecode(response.body);
      final accessToken = data['access_token'];

      final userInfoResponse = await http.get(
        Uri.parse('https://$domain/userinfo'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (userInfoResponse.statusCode != 200) {
        throw Exception('User info fetch failed');
      }

      final user = jsonDecode(userInfoResponse.body);
      setState(() {
        _isLoading = false;
      });
      return user;
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to authenticate: ${e.toString()}';
        _isLoading = false;
      });
      rethrow;
    }
  }

  Future<void> _handleUserRegistration(Map<String, dynamic> user) async {
    final String userId = user['sub'];
    try {
      final checkResponse = await http.post(
        Uri.parse('$apiUrl/sign-up'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': userId,
          'email': user['email'],
          'password': 'Auth0User${DateTime.now().millisecondsSinceEpoch}',
          'dob': DateTime.now().toIso8601String(), // Default value
          'university': 'Not specified',
          'graduationYear': DateTime.now().year + 4
        }),
      );

      final checkData = jsonDecode(checkResponse.body);

      if (checkResponse.statusCode == 409) {
        // User already exists, try to login
        final loginResponse = await http.post(
          Uri.parse('$apiUrl/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': user['email'],
            'password': 'Auth0User${DateTime.now().millisecondsSinceEpoch}',
          }),
        );

        if (loginResponse.statusCode == 200) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/filter');
          }
        } else {
          setState(() {
            _errorMessage = 'Failed to login with Auth0';
          });
        }
      } else if (checkResponse.statusCode == 201) {
        // New user created
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/filter');
        }
      } else {
        setState(() {
          _errorMessage = checkData['message'] ?? 'Failed to register user';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to register user: ${e.toString()}';
      });
    }
  }

  Future<void> _attemptRegularLogin() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      setState(() {
        _emailError = emailError;
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _passwordError = 'Password cannot be empty';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login successful!')),
          );
          Navigator.pushReplacementNamed(context, '/filter');
        }
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Login failed';
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    const Text(
                      'OpenIntern',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4285F4),
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleAuth0Login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4285F4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.security),
                      label: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text('Login with Auth0', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'OR',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Email',
                            style: TextStyle(
                              color: Color(0xFF4285F4),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'your.email@example.com',
                              errorText: _emailError,
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
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Password',
                            style: TextStyle(
                              color: Color(0xFF4285F4),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              errorText: _passwordError,
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
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _attemptRegularLogin,
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
                          'Login',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
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
                    const SizedBox(height: 20),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: Colors.grey[700],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacementNamed(context, '/signup');
                            },
                            child: const Text(
                              'Sign Up',
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
            ),
          ),
        ],
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
