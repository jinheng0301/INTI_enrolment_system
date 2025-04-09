class StudentEnrollCourse {
  final String studentId;
  final String courseId;
  final String courseName;
  final String lecturerName;
  final String schedule;
  final String venue;
  final int creditHours;
  final DateTime enrollmentDate;

  StudentEnrollCourse({
    required this.studentId,
    required this.courseId,
    required this.courseName,
    required this.lecturerName,
    required this.schedule,
    required this.venue,
    required this.creditHours,
    required this.enrollmentDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'courseId': courseId,
      'courseName': courseName,
      'lecturerName': lecturerName,
      'schedule': schedule,
      'venue': venue,
      'creditHours': creditHours,
      'enrollmentDate': enrollmentDate.toIso8601String(),
    };
  }
}
