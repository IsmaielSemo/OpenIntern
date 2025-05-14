import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _backendUrl = 'http://localhost:3000/generate';

  static Future<Map<String, dynamic>> generateCoverLetterAndCourses({
    required String jobTitle,
    required String company,
    required List<String> requiredSkills,
    required String detailedRequirements,
    String? userName,
    List<String>? userSkills,
    List<String>? userProjects,
    String mode = 'cover_letter',
  }) async {
    try {
      final body = {
        'jobTitle': jobTitle,
        'company': company,
        'requiredSkills': requiredSkills,
        'detailedRequirements': detailedRequirements,
        'mode': mode,
      };
      if (userName != null) body['userName'] = userName;
      if (userSkills != null) body['userSkills'] = userSkills;
      if (userProjects != null) body['userProjects'] = userProjects;
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        // The backend already parses and returns clean JSON, so we can directly decode it
        return jsonDecode(response.body);
      } else {
        print('Backend error: ${response.body}');
        throw Exception('Failed to generate content: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in generateCoverLetterAndCourses: $e');
      throw Exception('Error generating content: $e');
    }
  }

  Future<Map<String, dynamic>> generateContent({
    required String jobTitle,
    required String company,
    required List<String> requiredSkills,
    required String detailedRequirements,
    required String mode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jobTitle': jobTitle,
          'company': company,
          'requiredSkills': requiredSkills,
          'detailedRequirements': detailedRequirements,
          'mode': mode,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('Backend error: ${response.body}');
        throw Exception('Failed to generate content: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in generateContent: $e');
      throw Exception('Error generating content: $e');
    }
  }
}