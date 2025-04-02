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
}
