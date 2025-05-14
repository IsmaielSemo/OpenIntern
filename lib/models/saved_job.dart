import 'internship.dart';

class SavedJob extends Internship {
  final DateTime savedDate;

  SavedJob({
    required super.title,
    required super.company,
    required super.location,
    required super.jobType,
    required super.postedDate,
    required super.url,
    required super.skills,
    required super.experienceRequired,
    required super.educationRequired,
    required super.detailedRequirements,
    required super.additionalSkills,
    required super.isPaid,
    required super.isRemote,
    required this.savedDate,
  });

  factory SavedJob.fromInternship(Internship internship) {
    return SavedJob(
      title: internship.title,
      company: internship.company,
      location: internship.location,
      jobType: internship.jobType,
      postedDate: internship.postedDate,
      url: internship.url,
      skills: internship.skills,
      experienceRequired: internship.experienceRequired,
      educationRequired: internship.educationRequired,
      detailedRequirements: internship.detailedRequirements,
      additionalSkills: internship.additionalSkills,
      isPaid: internship.isPaid,
      isRemote: internship.isRemote,
      savedDate: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'company': company,
      'location': location,
      'jobType': jobType,
      'postedDate': postedDate,
      'url': url,
      'skills': skills,
      'experienceRequired': experienceRequired,
      'educationRequired': educationRequired,
      'detailedRequirements': detailedRequirements,
      'additionalSkills': additionalSkills,
      'isPaid': isPaid,
      'isRemote': isRemote,
      'savedDate': savedDate.toIso8601String(),
    };
  }

  factory SavedJob.fromJson(Map<String, dynamic> json) {
    return SavedJob(
      title: json['title'],
      company: json['company'],
      location: json['location'],
      jobType: json['jobType'],
      postedDate: json['postedDate'],
      url: json['url'],
      skills: List<String>.from(json['skills']),
      experienceRequired: json['experienceRequired'],
      educationRequired: json['educationRequired'],
      detailedRequirements: json['detailedRequirements'],
      additionalSkills: List<String>.from(json['additionalSkills']),
      isPaid: json['isPaid'],
      isRemote: json['isRemote'],
      savedDate: DateTime.parse(json['savedDate']),
    );
  }
} 