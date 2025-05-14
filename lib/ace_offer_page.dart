import 'package:flutter/material.dart';
import 'models/internship.dart';
import 'services/ai_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AceOfferPage extends StatefulWidget {
  final Internship internship;
  const AceOfferPage({Key? key, required this.internship}) : super(key: key);

  @override
  State<AceOfferPage> createState() => _AceOfferPageState();
}

class _AceOfferPageState extends State<AceOfferPage> with SingleTickerProviderStateMixin {
  bool _loading = false;
  String? _coverLetter;
  List<Map<String, String>>? _courses;
  List<String>? _questions;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data() ?? {};
    return {
      'name': data['fullName'] ?? '',
      'skills': List<String>.from(data['skills'] ?? []),
      'projects': List<String>.from(data['projects'] ?? []),
    };
  }

  void _fetchCoverLetter() async {
    setState(() {
      _loading = true;
      _coverLetter = null;
      _courses = null;
      _questions = null;
      _error = null;
    });
    try {
      final userData = await _fetchUserData();
      final matchingSkills = (userData['skills'] as List<String>).where((s) => widget.internship.skills.contains(s)).toList();
      final matchingProjects = (userData['projects'] as List<String>).where((p) => widget.internship.skills.any((s) => p.toLowerCase().contains(s.toLowerCase()))).toList();
      final result = await AIService.generateCoverLetterAndCourses(
        jobTitle: widget.internship.title,
        company: widget.internship.company,
        requiredSkills: widget.internship.skills,
        detailedRequirements: widget.internship.detailedRequirements,
        userName: userData['name'],
        userSkills: matchingSkills,
        userProjects: matchingProjects,
        mode: 'cover_letter',
      );
      setState(() {
        _coverLetter = result['coverLetter'] ?? 'No cover letter generated.';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  void _fetchCourses() async {
    setState(() {
      _loading = true;
      _coverLetter = null;
      _courses = null;
      _questions = null;
      _error = null;
    });
    try {
      final result = await AIService.generateCoverLetterAndCourses(
        jobTitle: widget.internship.title,
        company: widget.internship.company,
        requiredSkills: widget.internship.skills,
        detailedRequirements: widget.internship.detailedRequirements,
        mode: 'courses',
      );
      // Expecting: [{"name": "Course Name", "url": "https://..."}, ...]
      final List coursesRaw = result['recommendedCourses'] as List? ?? [];
      final List<Map<String, String>> courses =
          coursesRaw.map<Map<String, String>>((e) {
        if (e is Map) {
          return Map<String, String>.from(e);
        } else if (e is String) {
          return {"name": e, "url": ""};
        } else {
          return {"name": e.toString(), "url": ""};
        }
      }).toList();
      setState(() {
        _courses = courses;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  void _fetchQuestions() async {
    setState(() {
      _loading = true;
      _coverLetter = null;
      _courses = null;
      _questions = null;
      _error = null;
    });
    try {
      final result = await AIService.generateCoverLetterAndCourses(
        jobTitle: widget.internship.title,
        company: widget.internship.company,
        requiredSkills: widget.internship.skills,
        detailedRequirements: widget.internship.detailedRequirements,
        mode: 'questions',
      );
      final List<String> questions =
          (result['questions'] as List?)?.map((e) => e.toString()).toList() ??
              [];
      setState(() {
        _questions = questions;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  Widget _buildResult() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _getLoadingMessage(),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _retryLastAction,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    if (_coverLetter != null) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Generated Cover Letter:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy),
                          tooltip: 'Copy to clipboard',
                          onPressed: () {
                            // TODO: Implement copy to clipboard
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.share),
                          tooltip: 'Share cover letter',
                          onPressed: () {
                            // TODO: Implement share functionality
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(_coverLetter!),
              ],
            ),
          ),
        ),
      );
    }
    if (_courses != null) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _courses!.length,
          itemBuilder: (context, idx) {
            final course = _courses![idx];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.school),
                title: Text(course['name'] ?? ''),
                subtitle: course['url'] != null ? Text(course['url']!) : null,
                onTap: course['url'] != null
                    ? () async {
                        final url = Uri.parse(course['url']!);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      }
                    : null,
                trailing: course['url'] != null
                    ? const Icon(Icons.open_in_new)
                    : null,
              ),
            );
          },
        ),
      );
    }
    if (_questions != null) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _questions!.length,
          itemBuilder: (context, idx) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.question_answer),
              title: Text(_questions![idx]),
            ),
          ),
        ),
      );
    }
    return const Center(
      child: Text('Choose an option above to get started!',
          style: TextStyle(fontSize: 16)),
    );
  }

  String _getLoadingMessage() {
    if (_coverLetter != null) return 'Generating cover letter...';
    if (_courses != null) return 'Finding recommended courses...';
    if (_questions != null) return 'Preparing interview questions...';
    return 'Loading...';
  }

  void _retryLastAction() {
    if (_coverLetter != null) _fetchCoverLetter();
    if (_courses != null) _fetchCourses();
    if (_questions != null) _fetchQuestions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ace this Offer'),
        backgroundColor: const Color(0xFF4285F4),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF4285F4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AceOptionButton(
                  icon: Icons.description,
                  label: 'Get Cover Letter',
                  onTap: _fetchCoverLetter,
                  color: Colors.blue,
                  tooltip: 'Generate a personalized cover letter based on your profile',
                ),
                _AceOptionButton(
                  icon: Icons.school,
                  label: 'Recommended Courses',
                  onTap: _fetchCourses,
                  color: Colors.green,
                  tooltip: 'Get course recommendations to improve your skills',
                ),
                _AceOptionButton(
                  icon: Icons.psychology,
                  label: 'Interview Questions',
                  onTap: _fetchQuestions,
                  color: Colors.orange,
                  tooltip: 'Practice with interview questions tailored to this position',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildResult()),
        ],
      ),
    );
  }
}

class _AceOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final String tooltip;

  const _AceOptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        onPressed: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: Colors.white),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}