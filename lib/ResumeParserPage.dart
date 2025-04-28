import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'dart:convert';
import 'package:flutter/services.dart'; // for running shell commands
import 'dart:typed_data';

class ResumeParserPage extends StatefulWidget {
  final Function(List<String>) onResumeUploaded;

  const ResumeParserPage({Key? key, required this.onResumeUploaded})
      : super(key: key);

  @override
  _ResumeParserPageState createState() => _ResumeParserPageState();
}

class _ResumeParserPageState extends State<ResumeParserPage> {
  String _fileName = '';
  String _resumeUrl = '';
  List<Map<String, dynamic>> _recommendedJobs = [];
  bool _isLoading = false;
  String? _error;
  final TextEditingController _urlController = TextEditingController();

  Future<void> _parseResumeFromUrl() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _recommendedJobs = [];
    });
    try {
      final apiUrl =
          'https://api.apilayer.com/resume_parser/url?url=${Uri.encodeComponent(_resumeUrl)}';
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'apikey': 'mMihrXALP2tnGc7GrzZeGrjyj7GpmYUL'},
      );
      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');
      if (response.statusCode != 200) {
        setState(() {
          _error = 'Error parsing resume from URL: ${response.body}';
          _isLoading = false;
        });
        return;
      }
      final parsedData = json.decode(response.body);
      List<String> skills = List<String>.from(parsedData['skills'] ?? []);
      final jobs = await _loadJobs();
      _recommendedJobs = _rankJobs(jobs, skills);
      widget.onResumeUploaded(skills); // Pass parsed skills to the callback
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error parsing from URL: $e';
        _isLoading = false;
      });
    }
  }

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
      String? ext = file.extension?.toLowerCase();
      if (ext != 'pdf' && ext != 'docx') {
        setState(() {
          _error = 'Unsupported file format. Please upload a PDF or DOCX file.';
          _isLoading = false;
        });
        return;
      }
      if (file.size == 0) {
        setState(() {
          _error = 'File is empty. Please select a valid resume file.';
          _isLoading = false;
        });
        return;
      }
      Uint8List? fileBytes;
      if (kIsWeb) {
        if (file.bytes == null || file.bytes!.isEmpty) {
          setState(() {
            _error = 'No file data found. Please select a valid file.';
            _isLoading = false;
          });
          return;
        }
        fileBytes = file.bytes;
      } else {
        if (file.path == null || file.path!.isEmpty) {
          setState(() {
            _error = 'No file path found. Please select a valid file.';
            _isLoading = false;
          });
          return;
        }
        fileBytes = await File(file.path!).readAsBytes();
      }
      final response = await http.post(
        Uri.parse('https://api.apilayer.com/resume_parser/upload'),
        headers: {
          'Content-Type': 'application/octet-stream',
          'apikey': 'mMihrXALP2tnGc7GrzZeGrjyj7GpmYUL',
        },
        body: fileBytes,
      );
      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');
      if (response.statusCode == 400) {
        setState(() {
          _error =
              'API Error 400: The file format was not accepted by the API. Please ensure you are uploading a valid, standards-compliant PDF or DOCX file exported from Word or Google Docs.';
          _isLoading = false;
        });
        return;
      }
      if (response.statusCode != 200) {
        setState(() {
          _error =
              'Error parsing resume: Exception: API Error: ${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
        return;
      }
      final parsedData = json.decode(response.body);
      List<String> skills = List<String>.from(parsedData['skills'] ?? []);
      final jobs = await _loadJobs();
      _recommendedJobs = _rankJobs(jobs, skills);
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

  Future<List<Map<String, dynamic>>> _loadJobs() async {
    try {
      final String response =
          await DefaultAssetBundle.of(context).loadString('internships.json');
      return List<Map<String, dynamic>>.from(json.decode(response));
    } catch (e) {
      throw Exception('Error loading jobs: $e');
    }
  }

  List<Map<String, dynamic>> _rankJobs(
      List<Map<String, dynamic>> jobs, List<String> skills) {
    return jobs.map((job) {
      final jobSkills = List<String>.from(job['skills'] ?? []);
      final matchingSkills = skills
          .where((skill) => jobSkills.contains(skill.toLowerCase()))
          .length;
      return {
        ...job,
        'matchingSkills': matchingSkills,
      };
    }).toList()
      ..sort((a, b) => b['matchingSkills'].compareTo(a['matchingSkills']));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Parser'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Public Resume URL (PDF/DOCX)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => _resumeUrl = val,
              ),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _parseResumeFromUrl,
              child: Text(_isLoading ? 'Processing...' : 'Parse from URL'),
            ),
            const Divider(height: 32),
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
            if (_recommendedJobs.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _recommendedJobs.length,
                  itemBuilder: (context, index) {
                    final job = _recommendedJobs[index];
                    return ListTile(
                      title: Text(job['title'] ?? ''),
                      subtitle:
                          Text('Matching Skills: ${job['matchingSkills']}'),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}


