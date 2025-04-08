import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart'; // Add this package to pubspec.yaml
import 'package:http/http.dart' as http; // Add this package to pubspec.yaml
import 'dart:convert';
import 'validators.dart'; // Import the validators

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;
  bool _isLoading = false;
  String? _errorMessage;
  // Removed unused _userInfo field

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
    const String url = 'http://localhost:3000/sign-up';

    try {
      final checkResponse = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': userId, 'password': 'test123'}),
      );

      final checkData = jsonDecode(checkResponse.body);

      if (checkData['message'] == 'Username is already registered') {
        final setUsernameResponse = await http.post(
          Uri.parse('http://localhost:3000/set-username'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': userId}),
        );

        final setUsernameData = jsonDecode(setUsernameResponse.body);

        if (setUsernameData['status'] == 'Username set successfully') {
          Navigator.pushReplacementNamed(context, '/mynews');
        } else {
          setState(() {
            _errorMessage = 'Failed to set username.';
          });
        }
      } else {
        Navigator.pushReplacementNamed(context, '/preferences');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to register user: ${e.toString()}';
      });
    }
  }

  void _attemptRegularLogin() {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final emailError = Validators.validateEmail(email);
    final passwordError = Validators.validatePassword(password);

    if (emailError != null) {
      setState(() {
        _emailError = emailError;
      });
    }

    if (passwordError != null) {
      setState(() {
        _passwordError = passwordError;
      });
    }

    if (emailError == null && passwordError == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Regular login successful!')),
      );
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
                      icon: const Icon(Icons.security),
                      label: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Login with Auth0'),
                    ),
                    const SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'Email',
                              errorText: _emailError,
                            ),
                          ),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              errorText: _passwordError,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _attemptRegularLogin,
                      child: const Text('Login with Email'),
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
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