import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';
import 'models/internship.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();

  List<Internship> _allInternships = [];
  bool _isLoading = true;
  String? _error;

  String? _location;
  String? _company;
  String? _jobType; // Make it nullable to allow no selection
  List<String>? _requiredSkills;
  List<String> _selectedExperienceLevels = [];
  bool _isPaid = false;
  bool _isRemote = false;

  // Job type options
  final List<String> _jobTypes = [
    'Internship',
    'Full Time',
    'Part Time'
  ];

  // Experience level options
  final List<String> _experienceLevels = [
    'No Experience',
    '0-1 years',
    '1-3 years',
    '3-5 years',
    '5+ years'
  ];

  @override
  void dispose() {
    _locationController.dispose();
    _companyController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadInternships();
  }

  Future<void> _loadInternships() async {
    try {
      final String jsonString = await rootBundle.loadString('internships.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      final List<Internship> internships = jsonData.map((json) => Internship.fromJson(json)).toList();
      
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

  List<Internship> _filterInternships() {
    return _allInternships.where((internship) {
      bool matchesLocation = _location == null || _location!.isEmpty ||
          internship.location.toLowerCase().contains(_location!.toLowerCase());

      bool matchesCompany = _company == null || _company!.isEmpty ||
          internship.company.toLowerCase().contains(_company!.toLowerCase());

      bool matchesJobType = _jobType == null ||
          internship.jobType.toLowerCase() == _jobType!.toLowerCase();

      bool matchesSkills = _requiredSkills == null || _requiredSkills!.isEmpty ||
          _requiredSkills!.every((skill) => 
            internship.skills.any((s) => s.toLowerCase().contains(skill.toLowerCase())) ||
            internship.additionalSkills.any((s) => s.toLowerCase().contains(skill.toLowerCase())));

      bool matchesExperience = _selectedExperienceLevels.isEmpty ||
          _selectedExperienceLevels.any((level) {
            String expReq = internship.experienceRequired.toLowerCase();
            String detailedReqs = internship.detailedRequirements.toLowerCase();
            
            // First check if it's explicitly "Not specified"
            if (expReq == "not specified" && level == "No Experience") {
              return true;
            }

            // Helper function to extract years from string
            int? extractYears(String text) {
              final regex = RegExp(r'(\d+)(?=\s*(?:year|yr))');
              final match = regex.firstMatch(text);
              return match != null ? int.tryParse(match.group(1) ?? '') : null;
            }

            // Try to extract years from both experience required and detailed requirements
            int? years = extractYears(expReq);
            years ??= extractYears(detailedReqs);

            switch (level) {
              case 'No Experience':
                return expReq.contains('no experience') ||
                       expReq.contains('0-1') ||
                       expReq.contains('0 to 1') ||
                       expReq.contains('entry level') ||
                       detailedReqs.contains('no experience') ||
                       detailedReqs.contains('entry level') ||
                       detailedReqs.contains('fresh graduate') ||
                       (years != null && years == 0);

              case '0-1 years':
                return expReq.contains('0-1') ||
                       expReq.contains('0 to 1') ||
                       expReq.contains('entry level') ||
                       detailedReqs.contains('0-1') ||
                       detailedReqs.contains('0 to 1') ||
                       detailedReqs.contains('entry level') ||
                       (years != null && years <= 1);

              case '1-3 years':
                return expReq.contains('1-3') ||
                       expReq.contains('1 to 3') ||
                       expReq.contains('2-3') ||
                       expReq.contains('2 to 3') ||
                       detailedReqs.contains('1-3') ||
                       detailedReqs.contains('1 to 3') ||
                       (years != null && years > 1 && years <= 3);

              case '3-5 years':
                return expReq.contains('3-5') ||
                       expReq.contains('3 to 5') ||
                       expReq.contains('4-5') ||
                       expReq.contains('4 to 5') ||
                       detailedReqs.contains('3-5') ||
                       detailedReqs.contains('3 to 5') ||
                       (years != null && years > 3 && years <= 5);

              case '5+ years':
                return expReq.contains('5+') ||
                       expReq.contains('5 years') ||
                       expReq.contains('senior') ||
                       detailedReqs.contains('senior') ||
                       detailedReqs.contains('5+') ||
                       detailedReqs.contains('5 years') ||
                       (years != null && years > 5);

              default:
                return false;
            }
          });

      return matchesLocation && matchesCompany && matchesJobType &&
             matchesSkills && matchesExperience && 
             (!_isPaid || internship.isPaid) &&
             (!_isRemote || internship.isRemote);
    }).toList();
  }

  void _clearFilter() {
    setState(() {
      // Clear text field controllers
      _locationController.clear();
      _companyController.clear();
      _skillsController.clear();

      // Reset all filter values
      _location = null;
      _company = null;
      _jobType = null; // Set to null to unselect all radio buttons
      _requiredSkills = null;
      _selectedExperienceLevels = [];
      _isPaid = false;
      _isRemote = false;
    });

    // Reset form
    _formKey.currentState?.reset();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filters cleared!')),
    );
  }

  void _applyFilter() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Get the values from controllers
      _location = _locationController.text;
      _company = _companyController.text;
      _requiredSkills = _skillsController.text.isEmpty ? null : 
          _skillsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

      List<Internship> filteredInternships = _filterInternships();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FilterResultsScreen(internships: filteredInternships),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Filters applied successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter Internships'),
        backgroundColor: const Color(0xFF4285F4),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
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
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        // Location
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            hintText: 'Enter city or region',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Company
                        TextFormField(
                          controller: _companyController,
                          decoration: const InputDecoration(
                            labelText: 'Company',
                            hintText: 'Enter company name',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Job Type
                        const Text('Job Type:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Column(
                          children: _jobTypes.map((type) {
                            return RadioListTile<String?>(
                              title: Text(type),
                              value: type,
                              groupValue: _jobType,
                              onChanged: (String? value) {
                                setState(() {
                                  _jobType = value;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Skills
                        TextFormField(
                          controller: _skillsController,
                          decoration: const InputDecoration(
                            labelText: 'Required Skills',
                            hintText: 'e.g., Python, JavaScript, React (comma-separated)',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Experience Levels
                        const Text('Experience Level Required:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Wrap(
                          spacing: 8.0,
                          children: _experienceLevels.map((level) {
                            return FilterChip(
                              label: Text(level),
                              selected: _selectedExperienceLevels.contains(level),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedExperienceLevels.add(level);
                                  } else {
                                    _selectedExperienceLevels.remove(level);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Is Paid Switch
                        SwitchListTile(
                          title: const Text('Paid Internships Only'),
                          value: _isPaid,
                          onChanged: (bool value) {
                            setState(() {
                              _isPaid = value;
                            });
                          },
                        ),

                        // Is Remote Switch
                        SwitchListTile(
                          title: const Text('Remote Opportunities Only'),
                          value: _isRemote,
                          onChanged: (bool value) {
                            setState(() {
                              _isRemote = value;
                            });
                          },
                        ),

                        const SizedBox(height: 20),

                        // Apply Filter Button
                        ElevatedButton(
                          onPressed: _applyFilter,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4285F4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Apply Filters',
                              style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),

                        const SizedBox(height: 10),

                        // Clear Filter Button
                        OutlinedButton(
                          onPressed: _clearFilter,
                          style: ButtonStyle(
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                          child: const Text('Clear Filters',
                              style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class FilterResultsScreen extends StatelessWidget {
  final List<Internship> internships;

  const FilterResultsScreen({super.key, required this.internships});

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
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                    children: internship.skills.map((skill) => Chip(
                      label: Text(skill),
                      backgroundColor: Colors.blue.shade100,
                    )).toList(),
                  ),
                  if (internship.additionalSkills.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Additional Skills:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Wrap(
                      spacing: 8,
                      children: internship.additionalSkills.map((skill) => Chip(
                        label: Text(skill),
                        backgroundColor: Colors.green.shade100,
                      )).toList(),
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
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not launch the application URL'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
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
        title: const Text('Filter Results'),
        backgroundColor: const Color(0xFF4285F4),
      ),
      body: internships.isEmpty
          ? const Center(
              child: Text(
                'No internships match your filters',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: internships.length,
              itemBuilder: (context, index) {
                final internship = internships[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  child: InkWell(
                    onTap: () => _showDetailedView(context, internship),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            internship.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Company: ${internship.company}'),
                          Text('Location: ${internship.location}'),
                          Text('Job Type: ${internship.jobType}'),
                          ...[
                          Text('Posted: ${internship.postedDate}'),
                        ],
                          Row(
                            children: [
                              if (internship.isPaid)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  margin: const EdgeInsets.only(top: 8, right: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.attach_money, size: 14, color: Colors.green[700]),
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
                              if (internship.isRemote)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  margin: const EdgeInsets.only(top: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.home_work, size: 14, color: Colors.blue[700]),
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
                              children: internship.skills.take(3).map((skill) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          const SizedBox(height: 8),
                          Text(
                            'Tap to view details',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
