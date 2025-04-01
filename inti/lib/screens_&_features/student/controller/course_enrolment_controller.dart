import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/utils/utils.dart';
import 'package:inti/screens_&_features/student/repository/course_enrolment_repository.dart';

final courseEnrolmentControllerProvider = Provider((ref) {
  final repository = ref.watch(courseEnrolmentRepositoryProvider);
  return CourseEnrolmentController(repository: repository, ref: ref);
});

class CourseEnrolmentController {
  final CourseEnrolmentRepository repository;
  final Ref ref;

  CourseEnrolmentController({required this.repository, required this.ref});

  Future<void> enrollInCourse({
    //required String userId,
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
      await repository.enrollInCourse(
        //userId: userId,
        courseId: courseId,
        courseName: courseName,
        lecturerName: lecturerName,
        schedule: schedule,
        venue: venue,
        creditHours: creditHours,
        enrollmentDate: DateTime.now(),
      );

      showSnackBar(context, 'Successfully enrolled in $courseName!');
    } catch (e) {
      showSnackBar(context, 'Failed to enroll in course: $e');
    }
  }
}
