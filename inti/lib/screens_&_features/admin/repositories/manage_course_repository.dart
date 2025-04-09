import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/models/admin_add_course.dart';
import 'package:uuid/uuid.dart';

final manageCourseRepositoryProvider = Provider(
  (ref) => ManageCourseRepository(firestore: FirebaseFirestore.instance),
);

class ManageCourseRepository {
  final FirebaseFirestore firestore;

  ManageCourseRepository({required this.firestore});

  Future<void> addCourse({
    required String courseName,
    required String courseCode,
    required String lecturerName,
    required String schedule,
    required String venue,
    required int availableSeats,
    required int creditHours,
  }) async {
    try {
      String courseID = Uuid().v1();

      AdminAddCourse course = AdminAddCourse(
        id: courseID,
        courseName: courseName,
        courseCode: courseCode,
        lecturerName: lecturerName,
        schedule: schedule,
        venue: venue,
        availableSeats: availableSeats,
        creditHours: creditHours,
      );

      await firestore
          .collection('admin_add_courses')
          .doc(courseID)
          .set(course.toMap());

      print('✅ Course added successfully: ${course.toMap()}');
    } catch (e) {
      print('❌ Error adding course: $e');
      throw Exception("Error adding course: ${e.toString()}");
    }
  }

  Stream<List<AdminAddCourse>> getCourses() {
    try {
      return firestore.collection('courses').snapshots().map((snapshot) {
        print("Course snapshot received: ${snapshot.docs.length} documents");
        return snapshot.docs.map((doc) {
          try {
            return AdminAddCourse.fromMap(doc.data(), doc.id);
          } catch (e) {
            print("Error parsing course doc: $e");
            // Return a placeholder course or handle the error
            return AdminAddCourse(
              id: doc.id,
              courseName: "Error: ${e.toString().substring(0, 20)}...",
              courseCode: "",
              lecturerName: "",
              schedule: "",
              venue: "",
              availableSeats: 0,
              creditHours: 0,
            );
          }
        }).toList();
      });
    } catch (e) {
      print("Error in getCourses stream: $e");
      // Return an empty stream
      return Stream.value([]);
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
  }) async {
    try {
      await firestore.collection('admin_add_courses').doc(courseId).update({
        'courseName': courseName,
        'courseCode': courseCode,
        'lecturerName': lecturerName,
        'schedule': schedule,
        'venue': venue,
        'availableSeats': availableSeats,
        'creditHours': creditHours,
      });
    } catch (e) {
      throw Exception('Failed to edit course: $e');
    }
  }

  Future<void> deleteCourse({required String courseId}) async {
    try {
      await firestore.collection('admin_add_courses').doc(courseId).delete();
    } catch (e) {
      throw Exception('Failed to delete course: $e');
    }
  }
}
