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
        'used': false,
      });

      print("✅ Drop request submitted for course: $courseId");
    } catch (e) {
      print("❌ Error submitting drop request: $e");
      throw Exception('Failed to submit drop request: $e');
    }
  }

  Future<bool> checkIfCanAddCourse({required String studentId}) async {
    try {
      // Check if total enrolled courses is less than 5
      QuerySnapshot enrolledCourses =
          await firestore
              .collection('users')
              .doc(studentId)
              .collection('student_course_enrolment')
              .get();

      if (enrolledCourses.docs.length >= 5) {
        return false; // Already has 5 courses
      }

      // Check if at least one drop request has been approved
      QuerySnapshot approvedDrops =
          await firestore
              .collection('drop_requests')
              .where('studentId', isEqualTo: studentId)
              .where('status', isEqualTo: 'approved')
              .get();

      return approvedDrops.docs.isNotEmpty; // Can add if has an approved drop
    } catch (e) {
      print("❌ Error checking if can add course: $e");
      return false;
    }
  }

  Future<void> markDropRequestUsed({
    required String studentId,
    required String dropRequestId,
  }) async {
    try {
      // Update the drop request to indicate it has been used to add a new course
      await firestore.collection('drop_requests').doc(dropRequestId).update({
        'used': true,
        'usedDate': FieldValue.serverTimestamp(),
      });

      print("✅ Drop request marked as used: $dropRequestId");
    } catch (e) {
      print("❌ Error marking drop request as used: $e");
      throw Exception('Failed to update drop request status: $e');
    }
  }
}
