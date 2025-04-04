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
  Future<void> approveDropRequest(String requestId) async {
    try {
      // 1. Get the drop request document.
      DocumentSnapshot doc =
          await firestore.collection('drop_requests').doc(requestId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        // 2. Remove the course from student's enrolled courses.
        // Assumption: The document id in student's subcollection is the courseId.
        await firestore
            .collection('users')
            .doc(data['studentId'])
            .collection('student_course_enrolment')
            .doc(data['courseId'])
            .delete();

        // 3. Update the drop request status.
        await doc.reference.update({
          'status': 'Drop Approved',
          'processedDate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to approve drop: $e');
    }
  }

  // Reject drop request: Simply update the drop request status.
  Future<void> rejectDropRequest(String requestId) async {
    try {
      await firestore.collection('drop_requests').doc(requestId).update({
        'status': 'Drop Rejected',
        'processedDate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to reject drop: $e');
    }
  }
}
