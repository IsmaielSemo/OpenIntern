import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'filterscreen.dart' hide Internship;
import 'settingsscreen.dart';
import 'models/internship.dart';
import 'editprofilescreen.dart';
import 'ResumeParserPage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;
  List<Internship> _allInternships = [];
  bool _isLoading = true;
  String? _error;
  bool _hasUploadedResume = false; // Tracks if a resume has been uploaded
  List<String> _parsedSkills = []; // List to store parsed skills
  List<Internship> _recommendedInternships = []; // Store resulting internships
  final TextEditingController _urlController = TextEditingController();
  String _fileName = ''; // Store the name of the uploaded file

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController
        .addListener(_handleTabSelection); // Add listener for tab changes
    _loadInternships(); // Load internships from JSON file
    _checkResumeStatus(); // Check if a resume has been uploaded
  }

  void _onResumeUploaded(List<String> skills) {
    setState(() {
      _parsedSkills = skills;
      _recommendedInternships = _allInternships.where((internship) {
        final internshipSkills =
            internship.skills.map((skill) => skill.toLowerCase()).toList();
        return skills
            .any((skill) => internshipSkills.contains(skill.toLowerCase()));
      }).toList();
    });
  }

  // Handles tab selection changes
  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose(); // Dispose of the URL controller
    super.dispose();
    _tabController.dispose(); // Dispose of TabController
    super.dispose();
  }

  // Checks if a resume has been uploaded (placeholder logic)
  Future<void> _checkResumeStatus() async {
    setState(() {
      _hasUploadedResume = false; // Set to false for demo purposes
    });
  }

  // Refreshes recommendations based on parsed skills
  void _refreshRecommendations() {
    setState(() {
      // Trigger a rebuild to update recommendations
    });
  }

  Future<void> _loadInternships() async {
    try {
      final String jsonString = await rootBundle.loadString('internships.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      final List<Internship> internships =
          jsonData.map((json) => Internship.fromJson(json)).toList();

      setState(() {
        _allInternships = internships;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Navigates to the Resume Parser tab
  void _navigateToResumeUpload() {
    _tabController.animateTo(3); // Switch to the Resume Parser tab
  }

  // // Updates state when a resume is successfully uploaded
  // void _onResumeUploaded() {
  //   setState(() {
  //     _hasUploadedResume = true;
  //   });
  // }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
        withData: true,
      );
      if (result == null) {
        setState(() {
          _error = 'No file selected.';
          _isLoading = false;
        });
        return;
      }
      var file = result.files.single;
      setState(() {
        _fileName = file.name;
        _isLoading = true;
        _error = null;
      });
      Uint8List? fileBytes = file.bytes ?? await File(file.path!).readAsBytes();
      final response = await http.post(
        Uri.parse('https://api.apilayer.com/resume_parser/upload'),
        headers: {
          'Content-Type': 'application/octet-stream',
          'apikey': 'mMihrXALP2tnGc7GrzZeGrjyj7GpmYUL',
        },
        body: fileBytes,
      );
      if (response.statusCode != 200) {
        setState(() {
          _error = 'Error parsing resume: ${response.body}';
          _isLoading = false;
        });
        return;
      }
      final parsedData = json.decode(response.body);
      List<String> skills = List<String>.from(parsedData['skills'] ?? []);
      _onResumeUploaded(skills);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error picking or uploading file: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildRecommendedTab() {
    return Column(
      children: [
        // Resume Parsing Section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Public Resume URL (PDF/DOCX)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _pickFile,
                child: Text(_isLoading ? 'Processing...' : 'Upload Resume'),
              ),
              if (_fileName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('File: $_fileName'),
                ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
        const Divider(),

        // Recommended Internships Section
        Expanded(
          child: _buildInternshipList(_recommendedInternships),
        ),
      ],
    );
  }

  List<Internship> _getRecommendedInternships() {
    if (_hasUploadedResume && _parsedSkills.isNotEmpty) {
      return _allInternships.where((internship) {
        final internshipSkills =
            internship.skills.map((skill) => skill.toLowerCase()).toList();
        return _parsedSkills
            .any((skill) => internshipSkills.contains(skill.toLowerCase()));
      }).toList();
    }
    return [];
  }

  List<Internship> _getRecentlyAddedInternships() {
    // Sort by posted date and return the most recent 10
    final sorted = List<Internship>.from(_allInternships);
    sorted.sort((a, b) => (b.postedDate ?? '').compareTo(a.postedDate ?? ''));
    return sorted.take(10).toList();
  }

  void _showDetailedView(BuildContext context, Internship internship) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          internship.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Company: ${internship.company}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text('Location: ${internship.location}'),
                  Text('Job Type: ${internship.jobType}'),
                  Text('Posted: ${internship.postedDate}'),
                  Text('Experience: ${internship.experienceRequired}'),
                  Text('Education: ${internship.educationRequired}'),
                  const SizedBox(height: 8),
                  const Text(
                    'Required Skills:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 8,
                    children: internship.skills
                        .map((skill) => Chip(
                              label: Text(skill),
                              backgroundColor: Colors.blue.shade100,
                            ))
                        .toList(),
                  ),
                  if (internship.additionalSkills.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Additional Skills:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Wrap(
                      spacing: 8,
                      children: internship.additionalSkills
                          .map((skill) => Chip(
                                label: Text(skill),
                                backgroundColor: Colors.green.shade100,
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'Detailed Requirements:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(internship.detailedRequirements),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4285F4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        final Uri url = Uri.parse(internship.url);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                      child: const Text(
                        'Apply Now',
                        style: TextStyle(
                          color: Colors.white,
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenIntern'),
        backgroundColor: const Color(0xFF4285F4),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Recommended'),
            Tab(text: 'Recent'),
            Tab(text: 'All'),
          ],
        ),
        actions: [
          if (_tabController.index ==
              0) // Show refresh icon only on Recommended tab
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshRecommendations,
              tooltip: 'Refresh Recommendations',
            ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FilterScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: PageStorage(
        bucket: PageStorageBucket(),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildRecommendedTab(), // Replace this with the merged tab
            _buildInternshipList(_getRecentlyAddedInternships()), // Recent tab
            _buildInternshipList(_allInternships), // All tab
           
          ],
        ),
      ),
    );
  }

  Widget _buildInternshipList(List<Internship> internships) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading internships',
              style: TextStyle(
                fontSize: 20,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (internships.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No offers available yet',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please upload your resume to see matching internships.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: internships.length,
      itemBuilder: (context, index) {
        final internship = internships[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              _showDetailedView(context, internship);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    internship.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    internship.company,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        internship.location,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.work, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        internship.jobType,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      ...[
                        const SizedBox(width: 16),
                        Icon(Icons.access_time,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          internship.postedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (internship.isPaid)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.attach_money,
                                  size: 14, color: Colors.green[700]),
                              const SizedBox(width: 4),
                              Text(
                                'Paid',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (internship.isPaid && internship.isRemote)
                        const SizedBox(width: 8),
                      if (internship.isRemote)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.home_work,
                                  size: 14, color: Colors.blue[700]),
                              const SizedBox(width: 4),
                              Text(
                                'Remote',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (internship.skills.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: internship.skills.map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            skill,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[800],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
