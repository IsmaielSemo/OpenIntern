import 'package:flutter/material.dart';
import 'models/internship.dart';
import 'services/ai_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AceOfferPage extends StatefulWidget {
  final Internship internship;
  const AceOfferPage({Key? key, required this.internship}) : super(key: key);

  @override
  State<AceOfferPage> createState() => _AceOfferPageState();
}

class _AceOfferPageState extends State<AceOfferPage> {
  bool _loading = false;
  String? _coverLetter;
  List<Map<String, String>>? _courses; // [{name, url}]
  List<String>? _questions;
  String? _error;

  void _fetchCoverLetter() async {
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
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (_error != null) {
      return Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }
    if (_coverLetter != null) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Generated Cover Letter:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              Text(_coverLetter!),
            ],
          ),
        ),
      );
    }
    if (_courses != null) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _courses!.length,
        itemBuilder: (context, idx) {
          final course = _courses![idx];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
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
              trailing:
                  course['url'] != null ? const Icon(Icons.open_in_new) : null,
            ),
          );
        },
      );
    }
    if (_questions != null) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _questions!.length,
        itemBuilder: (context, idx) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.question_answer),
            title: Text(_questions![idx]),
          ),
        ),
      );
    }
    return const Center(
      child: Text('Choose an option above to get started!',
          style: TextStyle(fontSize: 16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ace this Offer'),
        backgroundColor: const Color(0xFF4285F4),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AceOptionButton(
                  icon: Icons.description,
                  label: 'Get Cover Letter',
                  onTap: _fetchCoverLetter,
                  color: Colors.blue,
                ),
                _AceOptionButton(
                  icon: Icons.school,
                  label: 'Recommended Courses',
                  onTap: _fetchCourses,
                  color: Colors.green,
                ),
                _AceOptionButton(
                  icon: Icons.psychology,
                  label: 'Interview Questions',
                  onTap: _fetchQuestions,
                  color: Colors.orange,
                ),
              ],
            ),
          ),
          const Divider(),
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
  const _AceOptionButton(
      {required this.icon,
      required this.label,
      required this.onTap,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
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
    );
  }
}
