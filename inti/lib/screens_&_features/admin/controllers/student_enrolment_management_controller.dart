import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/screens_&_features/admin/repositories/student_enrolment_management_repository.dart';

final studentEnrolmentManagementProvider = Provider((ref) {
  final repository = ref.watch(studentEnrolmentManagementRepository);
  return StudentEnrolmentManagementController(repository: repository, ref: ref);
});

class StudentEnrolmentManagementController {
  final StudentEnrolmentManagementRepository repository;
  final Ref ref;

  StudentEnrolmentManagementController({
    required this.repository,
    required this.ref,
  });

  // In StudentEnrolmentManagementController

  Future<void> approveDropRequest(String requestId) async {
    try {
      // 1. Get the drop request
      final doc =
          await FirebaseFirestore.instance
              .collection('drop_requests')
              .doc(requestId)
              .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        // 2. Remove from student's enrolled courses
        await FirebaseFirestore.instance
            .collection('users')
            .doc(data['studentId'])
            .collection('student_course_enrolment')
            .doc(data['courseId'])
            .delete();

        // 3. Update request status
        await doc.reference.update({
          'status': 'approved',
          'processedDate': Timestamp.now(),
        });
      }
    } catch (e) {
      throw Exception('Failed to approve drop: $e');
    }
  }

  Future<void> rejectDropRequest(String requestId) async {
    await FirebaseFirestore.instance
        .collection('drop_requests')
        .doc(requestId)
        .update({'status': 'rejected', 'processedDate': Timestamp.now()});
  }
}
