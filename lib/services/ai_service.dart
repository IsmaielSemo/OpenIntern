import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _backendUrl = 'http://localhost:3000/generate';

  static Future<Map<String, dynamic>> generateCoverLetterAndCourses({
    required String jobTitle,
    required String company,
    required List<String> requiredSkills,
    required String detailedRequirements,
    String mode = 'cover_letter',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
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
        final responseData = jsonDecode(response.body);
        // Try to extract the generated content from the backend's response
        // The OpenRouter response is inside responseData['choices'][0]['message']['content']
        if (responseData['choices'] != null &&
            responseData['choices'][0]['message'] != null &&
            responseData['choices'][0]['message']['content'] != null) {
          final generatedText = responseData['choices'][0]['message']['content'];
          final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(generatedText);
          if (jsonMatch != null) {
            return jsonDecode(jsonMatch.group(0)!);
          }
        }
        throw Exception('Failed to parse AI response');
      } else {
        print('Backend error: ${response.body}');
        throw Exception('Failed to generate content: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error generating content: $e');
    }
  }
} 