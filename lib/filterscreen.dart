import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class Internship {
  final String location;
  final String experienceLevel;
  final int duration;
  final bool isPaid;
  final String field;
  final bool isRemote;
  final bool hasJobOffer;

  Internship({
    required this.location,
    required this.experienceLevel,
    required this.duration,
    required this.isPaid,
    required this.field,
    required this.isRemote,
    required this.hasJobOffer,
  });

  factory Internship.fromJson(Map<String, dynamic> json) {
    return Internship(
      location: json['Location'] ?? '',
      experienceLevel: json['Experience Level'] ?? '',
      duration: json['Duration (Months)'] ?? 0,
      isPaid: json['Is Paid'] == 'Yes',
      field: json['Field'] ?? '',
      isRemote: json['Is Remote?'] == 'Yes',
      hasJobOffer: json['Has Job Offer?'] == 'Yes',
    );
  }
}

class FilterScreen extends StatefulWidget {
  const FilterScreen({Key? key}) : super(key: key);

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  final _formKey = GlobalKey<FormState>();

  List<Internship> _allInternships = [];

  String? _location;
  double? _salaryRange;
  String? _experienceLevel;
  int? _duration;
  bool _isPaid = false;
  String? _field;
  bool _isRemote = false;
  bool _hasJobOffer = false;

  @override
  void initState() {
    super.initState();
    _loadInternshipData();
  }

  Future<void> _loadInternshipData() async {
    try {
      final String response = await rootBundle.loadString('assets/internships.json');
      final List<dynamic> data = jsonDecode(response);
      setState(() {
        _allInternships = data.map((json) => Internship.fromJson(json)).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  void _applyFilter() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      List<Internship> filteredInternships = _filterInternships();

      // Navigate to results page
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

  List<Internship> _filterInternships() {
    return _allInternships.where((internship) {
      bool matchesLocation = _location == null || _location!.isEmpty ||
          internship.location.toLowerCase().contains(_location!.toLowerCase());

      // For salary, we'll just check if it's paid when the user wants paid internships
      bool matchesSalary = _salaryRange == null || (internship.isPaid);

      bool matchesExperience = _experienceLevel == null ||
          internship.experienceLevel == _experienceLevel;

      bool matchesDuration = _duration == null ||
          internship.duration <= _duration!;

      bool matchesPaid = !_isPaid || internship.isPaid;

      bool matchesField = _field == null || _field!.isEmpty ||
          internship.field.toLowerCase().contains(_field!.toLowerCase());

      bool matchesRemote = !_isRemote || internship.isRemote;

      bool matchesJobOffer = !_hasJobOffer || internship.hasJobOffer;

      return matchesLocation && matchesSalary && matchesExperience &&
          matchesDuration && matchesPaid && matchesField &&
          matchesRemote && matchesJobOffer;
    }).toList();
  }

  void _clearFilter() {
    setState(() {
      _location = null;
      _salaryRange = null;
      _experienceLevel = null;
      _duration = null;
      _isPaid = false;
      _field = null;
      _isRemote = false;
      _hasJobOffer = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filters cleared!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter Jobs'),
        backgroundColor: const Color(0xFF4285F4),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Location
              TextFormField(
                decoration: const InputDecoration(labelText: 'Location'),
                onSaved: (value) => _location = value,
              ),
              const SizedBox(height: 16),

              // Salary Range
              TextFormField(
                decoration: const InputDecoration(labelText: 'Salary Range'),
                keyboardType: TextInputType.number,
                onSaved: (value) =>
                _salaryRange = double.tryParse(value ?? ''),
              ),
              const SizedBox(height: 16),

              // Experience Level
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Experience Level'),
                items: const [
                  DropdownMenuItem(value: 'Entry', child: Text('Entry')),
                  DropdownMenuItem(value: 'Mid', child: Text('Mid')),
                  DropdownMenuItem(value: 'Senior', child: Text('Senior')),
                ],
                onChanged: (value) => setState(() {
                  _experienceLevel = value;
                }),
                value: _experienceLevel,
              ),
              const SizedBox(height: 16),

              // Duration
              TextFormField(
                decoration: const InputDecoration(labelText: 'Duration (in months)'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _duration = int.tryParse(value ?? ''),
              ),
              const SizedBox(height: 16),

              // Is Paid
              SwitchListTile(
                title: const Text('Is Paid'),
                value: _isPaid,
                onChanged: (value) => setState(() {
                  _isPaid = value;
                }),
              ),

              // Field
              TextFormField(
                decoration: const InputDecoration(labelText: 'Field'),
                onSaved: (value) => _field = value,
              ),
              const SizedBox(height: 16),

              // Is Remote
              SwitchListTile(
                title: const Text('Is Remote'),
                value: _isRemote,
                onChanged: (value) => setState(() {
                  _isRemote = value;
                }),
              ),

              // Has Job Offer
              SwitchListTile(
                title: const Text('Has Job Offer'),
                value: _hasJobOffer,
                onChanged: (value) => setState(() {
                  _hasJobOffer = value;
                }),
              ),

              const SizedBox(height: 20),

              // Apply Filter Button
              ElevatedButton(
                onPressed: _applyFilter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4285F4),
                ),
                child: const Text('Apply Filter'),
              ),

              const SizedBox(height: 10),

              // Clear Filter Button
              OutlinedButton(
                onPressed: _clearFilter,
                child: const Text('Clear Filter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// New screen to display filter results
class FilterResultsScreen extends StatelessWidget {
  final List<Internship> internships;

  const FilterResultsScreen({Key? key, required this.internships}) : super(key: key);

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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    internship.field,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Location: ${internship.location}'),
                  Text('Experience Level: ${internship.experienceLevel}'),
                  Text('Duration: ${internship.duration} months'),
                  Text('Field: ${internship.field}'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Chip(
                        label: Text(internship.isRemote ? 'Remote' : 'On-site'),
                        backgroundColor: internship.isRemote
                            ? Colors.green.shade100
                            : Colors.blue.shade100,
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(internship.isPaid ? 'Paid' : 'Unpaid'),
                        backgroundColor: internship.isPaid
                            ? Colors.green.shade100
                            : Colors.orange.shade100,
                      ),
                      const SizedBox(width: 8),
                      if (internship.hasJobOffer)
                        Chip(
                          label: const Text('Job Offer'),
                          backgroundColor: Colors.purple.shade100,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
