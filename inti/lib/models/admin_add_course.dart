class AdminAddCourse {
  final String id;
  final String courseName;
  final String courseCode;
  final String lecturerName;
  final String schedule;
  final String venue;
  final int availableSeats;
  final int creditHours;

  AdminAddCourse({
    required this.id,
    required this.courseName,
    required this.courseCode,
    required this.lecturerName,
    required this.schedule,
    required this.venue,
    required this.availableSeats,
    required this.creditHours,
  });

  Map<String, dynamic> toMap() {
    return {
      'courseName': courseName,
      'courseCode': courseCode,
      'lecturerName': lecturerName,
      'schedule': schedule,
      'venue': venue,
      'availableSeats': availableSeats,
      'creditHours': creditHours,
    };
  }

  factory AdminAddCourse.fromMap(Map<String, dynamic> map, String id) {
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

    return AdminAddCourse(
      id: id,
      courseName: parseField(map['courseName']),
      courseCode: parseField(map['courseCode']),
      lecturerName: parseField(map['lecturerName']),
      schedule: parseField(map['schedule']),
      venue: parseField(map['venue']),
      availableSeats:
          map['availableSeats'] is int
              ? map['availableSeats']
              : int.tryParse(map['availableSeats'].toString()) ?? 0,
      creditHours:
          map['creditHours'] is int
              ? map['creditHours']
              : int.tryParse(map['creditHours'].toString()) ?? 0,
    );
  }
}
