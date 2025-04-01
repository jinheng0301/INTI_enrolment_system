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
    //required String userId,
    required String courseId,
    required String courseName,
    required String lecturerName,
    required String schedule,
    required String venue,
    required int creditHours,
    required DateTime enrollmentDate,
  }) async {
    try {
      // Generate a unique enrollment ID
      String enrolmentId = Uuid().v1();

      // Create the enrollment object (assuming you have a toMap() method in your model)
      Enrolment enrolment = Enrolment(
        //studentId: userId,
        courseId: courseId,
        courseName: courseName,
        lecturerName: lecturerName,
        schedule: schedule,
        venue: venue,
        creditHours: creditHours,
        enrollmentDate: enrollmentDate,
      );

      // Save the enrollment data under the student's document using the unique enrollment ID
      await firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('student_course_enrolment')
          .doc(enrolmentId)
          .set(enrolment.toMap());

      print("✅ Enrollment added course: $courseId");
    } catch (e) {
      print("❌ Error enrolling in course: $e");
      throw Exception('Failed to enroll in course: $e');
    }
  }
}
