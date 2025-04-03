import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/models/enrolment.dart';
import 'package:uuid/uuid.dart';

final courseEnrolmentRepositoryProvider = Provider(
  (ref) => CourseEnrolmentRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  ),
);

class CourseEnrolmentRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  CourseEnrolmentRepository({required this.firestore, required this.auth});

  Future<void> enrollInCourse({
    required String userId,
    required String courseId,
    required String courseName,
    required String lecturerName,
    required String schedule,
    required String venue,
    required int creditHours,
    required DateTime enrollmentDate,
  }) async {
    try {
      DocumentReference userDocRef = firestore.collection('users').doc(userId);

      // Debug: Check if userId is valid
      print("🔍 User ID: $userId");

      // Ensure user document exists
      await userDocRef.set({'exists': true}, SetOptions(merge: true));
      print("✅ User document ensured.");

      String enrolmentId = Uuid().v1();
      print("🔍 Generated Enrolment ID: $enrolmentId");

      Enrolment enrolment = Enrolment(
        studentId: userId,
        courseId: courseId,
        courseName: courseName,
        lecturerName: lecturerName,
        schedule: schedule,
        venue: venue,
        creditHours: creditHours,
        enrollmentDate: enrollmentDate,
      );

      print("🔍 Enrolment Data: ${enrolment.toMap()}");

      await userDocRef
          .collection('student_course_enrolment')
          .doc(enrolmentId)
          .set(enrolment.toMap());

      print("✅ Enrollment added for course: $courseId");
    } catch (e) {
      print("❌ Error enrolling in course: $e");
      throw Exception('Failed to enroll in course: $e');
    }
  }

  Future<void> submitDropRequest({
    required String studentId,
    required String studentName,
    required String courseId,
    required String courseName,
    required String dropReason,
  }) async {
    try {
      // Check if a pending drop request already exists for this student & course.
      QuerySnapshot existingRequests =
          await firestore
              .collection('drop_requests')
              .where('studentId', isEqualTo: studentId)
              .where('courseId', isEqualTo: courseId)
              .where('status', isEqualTo: 'pending')
              .get();

      if (existingRequests.docs.isNotEmpty) {
        // A pending drop request already exists.
        throw Exception('A drop request for this course is already pending.');
      }

      // Generate a unique ID for the drop request.
      String dropRequestId = Uuid().v1();

      // Create drop request document in "drop_requests" collection.
      await firestore.collection('drop_requests').doc(dropRequestId).set({
        'studentId': studentId,
        'studentName': studentName,
        'courseId': courseId,
        'courseName': courseName,
        'dropReason': dropReason,
        'status': 'pending', // Options: pending/approved/rejected
        'requestDate': FieldValue.serverTimestamp(),
        'processedDate': null,
      });

      print("✅ Drop request submitted for course: $courseId");
    } catch (e) {
      print("❌ Error submitting drop request: $e");
      throw Exception('Failed to submit drop request: $e');
    }
  }
}
