import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/utils/utils.dart';
import 'package:inti/screens_&_features/student/repository/course_enrolment_repository.dart';

final courseEnrolmentControllerProvider = Provider((ref) {
  return CourseEnrolmentProviderController(
    courseEnrolmentRepository: ref.read(courseEnrolmentRepositoryProvider),
  );
});

class CourseEnrolmentProviderController {
  final CourseEnrolmentRepository courseEnrolmentRepository;

  CourseEnrolmentProviderController({required this.courseEnrolmentRepository});

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
      // Call the repository method to handle Firestore operations
      await courseEnrolmentRepository.enrollInCourse(
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
      showSnackBar(context, 'Successfully enrolled in the course!');
    } catch (e) {
      // Handle errors and show an error message
      showSnackBar(context, 'Failed to enroll in the course: $e');
    }
  }
}
