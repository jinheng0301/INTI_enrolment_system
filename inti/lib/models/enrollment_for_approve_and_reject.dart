import 'package:cloud_firestore/cloud_firestore.dart';

class EnrollmentForApproveAndReject {
  final String id;
  final String studentId;
  final String studentName;
  final String courseId;
  final String courseName;
  final String status;
  final DateTime enrolledAt;

  EnrollmentForApproveAndReject({
    this.id = '',
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.courseName,
    this.status = 'pending',
    required this.enrolledAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'courseId': courseId,
      'courseName': courseName,
      'status': status,
      'enrolledAt': Timestamp.fromDate(enrolledAt),
    };
  }

  static EnrollmentForApproveAndReject fromMap(Map<String, dynamic> map, String id) {
    return EnrollmentForApproveAndReject(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      courseId: map['courseId'] ?? '',
      courseName: map['courseName'] ?? '',
      status: map['status'] ?? 'pending',
      enrolledAt: (map['enrolledAt'] as Timestamp).toDate(),
    );
  }
}