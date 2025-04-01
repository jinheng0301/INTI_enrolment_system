import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final courseEnrolmentControllerProvider = Provider((ref) {
  // Define your controller logic here
  return CourseEnrolmentController();
});

class CourseEnrolmentController {
  Future<void> enrollInCourse({
    required String userId,
    required String courseId,
    required String courseName,
    required String lecturerName,
    required String schedule,
    required String venue,
    required int creditHours,
    required BuildContext context,
  }) async {
    // Enrollment logic here
  }
}