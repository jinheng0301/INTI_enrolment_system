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

  Future<void> updateEnrollmentStatus({
    required String enrollmentId,
    required String status,
  }) async {
    await firestore
        .collection('enrollments')
        .doc(enrollmentId)
        .update({'status': status});
  }
}