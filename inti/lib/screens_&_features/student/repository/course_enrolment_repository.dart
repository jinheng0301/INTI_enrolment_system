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
}
