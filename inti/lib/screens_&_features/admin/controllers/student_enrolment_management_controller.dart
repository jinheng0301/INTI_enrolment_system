import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/utils/utils.dart';
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

  Future<void> approveDropRequest(
    String requestId,
    BuildContext context,
  ) async {
    try {
      await repository.approveDropRequest(requestId);
      showSnackBar(context, 'Drop request approved.');
    } catch (e) {
      showSnackBar(context, 'Failed to approve drop request: $e');
    }
  }

  Future<void> rejectDropRequest(String requestId, BuildContext context) async {
    try {
      await repository.rejectDropRequest(requestId);
      showSnackBar(context, 'Drop request rejected.');
    } catch (e) {
      showSnackBar(context, 'Failed to reject drop request: $e');
    }
  }
}
