class Internship {
  final String id;
  final String title;
  final String company;
  final String location;
  final String jobType;
  final String postedDate;
  final String url;
  final List<String> skills;
  final String experienceRequired;
  final String educationRequired;
  final String detailedRequirements;
  final List<String> additionalSkills;
  final bool isPaid;
  final bool isRemote;

  Internship({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.jobType,
    required this.postedDate,
    required this.url,
    required this.skills,
    required this.experienceRequired,
    required this.educationRequired,
    required this.detailedRequirements,
    required this.additionalSkills,
    required this.isPaid,
    required this.isRemote,
  });

  factory Internship.fromJson(Map<String, dynamic> json) {
    String detailedReqs = json['detailed_requirements']?.toString().toLowerCase() ?? '';
    String locationStr = json['location']?.toString().toLowerCase() ?? '';
    String jobType = json['job_type']?.toString().toLowerCase() ?? '';

    // Check if the internship is paid by looking for salary-related keywords
    bool isPaid = detailedReqs.contains('salary') ||
                 detailedReqs.contains('paid') ||
                 detailedReqs.contains('compensation') ||
                 detailedReqs.contains('egp') ||
                 detailedReqs.contains('gbp') ||
                 detailedReqs.contains('usd');

    // Check if the internship is remote
    bool isRemote = detailedReqs.contains('remote') ||
                   locationStr.contains('remote') ||
                   detailedReqs.contains('work from home') ||
                   detailedReqs.contains('wfh') ||
                   locationStr.contains('work from home') ||
                   locationStr.contains('wfh');

    // Normalize job type
    String normalizedJobType = jobType;
    if (jobType.contains('intern') || jobType.contains('trainee')) {
      normalizedJobType = 'Internship';
    } else if (jobType.contains('full')) {
      normalizedJobType = 'Full Time';
    } else if (jobType.contains('part')) {
      normalizedJobType = 'Part Time';
    }

    return Internship(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      company: json['company'] ?? '',
      location: locationStr,
      jobType: normalizedJobType,
      postedDate: json['posted_date'] ?? '',
      url: json['url'] ?? '',
      skills: List<String>.from(json['skills'] ?? []),
      experienceRequired: json['experience_required'] ?? '',
      educationRequired: json['education_required'] ?? '',
      detailedRequirements: detailedReqs,
      additionalSkills: List<String>.from(json['additional_skills'] ?? []),
      isPaid: isPaid,
      isRemote: isRemote,
    );
  }
} 