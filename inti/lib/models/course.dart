class Course {
  final String id;
  final String courseName;
  final String courseCode;
  final String lecturerName;
  final String schedule;
  final String venue;
  final int availableSeats;
  final int creditHours;

  Course({
    this.id = '',
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

  static Course fromMap(Map<String, dynamic> map, String id) {
    return Course(
      id: id,
      courseName: map['courseName'],
      courseCode: map['courseCode'],
      lecturerName: map['lecturerName'],
      schedule: map['schedule'],
      venue: map['venue'],
      availableSeats: map['availableSeats'],
      creditHours: map['creditHours'],
    );
  }
}
