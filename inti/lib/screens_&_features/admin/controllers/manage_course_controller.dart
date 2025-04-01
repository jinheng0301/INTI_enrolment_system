import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/utils/utils.dart';
import 'package:inti/models/course.dart';
import 'package:inti/screens_&_features/admin/repositories/manage_course_repository.dart';

final manageCourseControllerProvider = Provider((ref) {
  final repository = ref.watch(manageCourseRepositoryProvider);
  return ManageCourseController(repository: repository, ref: ref);
});

final coursesStreamProvider = StreamProvider.autoDispose<List<Course>>((ref) {
  return FirebaseFirestore.instance
      .collection(
        'admin_add_courses',
      ) // Ensure this matches your Firestore collection name
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs
                .map((doc) => Course.fromMap(doc.data(), doc.id))
                .toList(),
      );
});

class ManageCourseController {
  final ManageCourseRepository repository;
  final Ref ref;

  ManageCourseController({required this.repository, required this.ref});

  Future<void> addCourse({
    required String courseName,
    required String courseCode,
    required String lecturerName,
    required String schedule,
    required String venue,
    required int availableSeats,
    required int creditHours,
    required BuildContext context,
  }) async {
    try {
      await repository.addCourse(
        courseName: courseName,
        courseCode: courseCode,
        lecturerName: lecturerName,
        schedule: schedule,
        venue: venue,
        availableSeats: availableSeats,
        creditHours: creditHours,
      );

      showSnackBar(context, 'Course added successfully!');
    } catch (e) {
      showSnackBar(context, 'Failed to add course: ${e.toString()}');
    }
  }

  Future<void> editCourse({
    required String courseId,
    required String courseName,
    required String courseCode,
    required String lecturerName,
    required String schedule,
    required String venue,
    required int availableSeats,
    required int creditHours,
    required BuildContext context,
  }) async {
    try {
      await repository.editCourse(
        courseId: courseId,
        courseName: courseName,
        courseCode: courseCode,
        lecturerName: lecturerName,
        schedule: schedule,
        venue: venue,
        availableSeats: availableSeats,
        creditHours: creditHours,
      );

      showSnackBar(context, 'Course updated successfully!');
    } catch (e) {
      showSnackBar(context, 'Failed to update course: $e');
    }
  }

  Future<void> deleteCourse({
    required String courseId,
    required BuildContext context,
  }) async {
    try {
      await repository.deleteCourse(courseId: courseId);

      showSnackBar(context, 'Course deleted successfully!');
    } catch (e) {
      showSnackBar(context, 'Failed to delete course: $e');
    }
  }
}
