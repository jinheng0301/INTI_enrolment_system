import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final studentEnrolmentManagementRepository = Provider(
  (ref) => StudentEnrolmentManagementRepository(
    firestore: FirebaseFirestore.instance,
  ),
);

class StudentEnrolmentManagementRepository {
  final FirebaseFirestore firestore;

  StudentEnrolmentManagementRepository({required this.firestore});

  // Approve drop request:
  // 1. Remove course from student's enrolled courses.
  // 2. Update the drop request status.
  // In StudentEnrolmentManagementRepository
  Future<void> approveDropRequest(String requestId) async {
    try {
      final doc =
          await firestore.collection('drop_requests').doc(requestId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        // 1. Find enrollment document by courseId
        QuerySnapshot enrollmentQuery =
            await firestore
                .collection('users')
                .doc(data['studentId'])
                .collection('student_course_enrolment')
                .where('courseId', isEqualTo: data['courseId'])
                .get();

        // 2. Delete the enrollment
        for (var doc in enrollmentQuery.docs) {
          await doc.reference.delete();
        }

        // 3. Update drop request status to approved (instead of deleting)
        await firestore.collection('drop_requests').doc(requestId).update({
          'status': 'approved',
          'processedDate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to approve drop: $e');
    }
  }

  Future<void> rejectDropRequest(String requestId) async {
    try {
      // Update status to rejected (instead of deleting)
      await firestore.collection('drop_requests').doc(requestId).update({
        'status': 'rejected',
        'processedDate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to reject drop: $e');
    }
  }
}
