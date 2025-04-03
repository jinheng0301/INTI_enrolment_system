import 'package:cloud_firestore/cloud_firestore.dart';

class DropRequest {
  final String id;
  final String studentId;
  final String studentName;
  final String courseId;
  final String courseName;
  final String status; // pending/approved/rejected
  final String dropReason;
  final DateTime requestDate;
  final DateTime? processedDate;

  DropRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.courseName,
    required this.status,
    required this.dropReason,
    required this.requestDate,
    this.processedDate,
  });

  // Factory method to create a DropRequest from Firestore DocumentSnapshot
  factory DropRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DropRequest(
      id: doc.id,
      studentId: data['studentId'],
      studentName: data['studentName'],
      courseId: data['courseId'],
      courseName: data['courseName'],
      status: data['status'],
      dropReason: data['dropReason'],
      requestDate: (data['requestDate'] as Timestamp).toDate(),
      processedDate: data['processedDate']?.toDate(),
    );
  }

  // Factory method to create a DropRequest from a Map
  factory DropRequest.fromMap(Map<String, dynamic> data, String id) {
    return DropRequest(
      id: id,
      studentId: data['studentId'],
      studentName: data['studentName'],
      courseId: data['courseId'],
      courseName: data['courseName'],
      status: data['status'],
      dropReason: data['dropReason'],
      requestDate: (data['requestDate'] as Timestamp).toDate(),
      processedDate: data['processedDate']?.toDate(),
    );
  }

  // Method to convert DropRequest to a Map
  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'courseId': courseId,
      'courseName': courseName,
      'status': status,
      'dropReason': dropReason,
      'requestDate': Timestamp.fromDate(requestDate),
      'processedDate':
          processedDate != null ? Timestamp.fromDate(processedDate!) : null,
    };
  }
}
