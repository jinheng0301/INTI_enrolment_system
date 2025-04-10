class StudentEnrollCourse {
  final String studentId;
  final String courseId;
  final String courseName;
  final String lecturerName;
  final List<Map<String, dynamic>> schedule;
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

  factory StudentEnrollCourse.fromMap(Map<String, dynamic> map, String id) {
    String parseField(dynamic field) {
      // If field is a list, convert it to a comma-separated string.
      if (field is List) {
        return field.join(', ');
      } else if (field is String) {
        return field;
      } else {
        return ''; // fallback if field is null or another type.
      }
    }

    return StudentEnrollCourse(
      studentId: parseField(map['studentId']),
      courseName: parseField(map['courseName']),
      courseId: parseField(map['courseId']),
      lecturerName: parseField(map['lecturerName']),
      schedule: (map['schedule'] as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList(),
      venue: parseField(map['venue']),
      creditHours: map['creditHours'] is int
          ? map['creditHours']
          : int.tryParse(map['creditHours'].toString()) ?? 0,
      enrollmentDate: DateTime.parse(map['enrollmentDate']),
    );
  }
}
