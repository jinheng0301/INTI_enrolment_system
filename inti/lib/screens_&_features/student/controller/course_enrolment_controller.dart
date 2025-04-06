import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/utils/utils.dart';
import 'package:inti/screens_&_features/student/repository/course_enrolment_repository.dart';

// Provide the CourseEnrolmentController with access to the repository
final courseEnrolmentControllerProvider = Provider((ref) {
  final repository = ref.watch(courseEnrolmentRepositoryProvider);
  return CourseEnrolmentController(repository: repository);
});

class CourseEnrolmentController {
  final CourseEnrolmentRepository repository;

  CourseEnrolmentController({required this.repository});

  Future<void> enrollInCourse({
    required String userId,
    required String courseId,
    required String courseName,
    required String lecturerName,
    required String schedule,
    required String venue,
    required int creditHours,
    required BuildContext context,
    required DateTime enrollmentDate,
  }) async {
    try {
      // Call the repository method to handle Firestore write
      await repository.enrollInCourse(
        userId: userId,
        courseId: courseId,
        courseName: courseName,
        lecturerName: lecturerName,
        schedule: schedule,
        venue: venue,
        creditHours: creditHours,
        enrollmentDate: enrollmentDate,
      );

      // Show success message
      showSnackBar(context, 'Successfully enrolled in $courseName!');
    } catch (e) {
      // Show error message
      showSnackBar(context, 'Failed to enroll: $e');
    }
  }

  Future<void> submitDropRequest({
    required String studentId,
    required String studentName,
    required String courseId,
    required String courseName,
    required String dropReason,
    required BuildContext context,
  }) async {
    try {
      await repository.submitDropRequest(
        studentId: studentId,
        studentName: studentName,
        courseId: courseId,
        courseName: courseName,
        dropReason: dropReason,
      );
      showSnackBar(context, 'Drop request submitted for $courseName!');
    } catch (e) {
      showSnackBar(context, 'Failed to submit drop request: $e');
    }
  }

  Future<bool> canAddCourse({required String studentId}) async {
    try {
      return await repository.checkIfCanAddCourse(studentId: studentId);
    } catch (e) {
      print("❌ Controller error checking if can add course: $e");
      return false;
    }
  }

  Future<void> markDropRequestUsed({
    required String studentId,
    required String dropRequestId,
  }) async {
    try {
      await repository.markDropRequestUsed(
        studentId: studentId,
        dropRequestId: dropRequestId,
      );
    } catch (e) {
      print("❌ Controller error marking drop request as used: $e");
    }
  }
}
