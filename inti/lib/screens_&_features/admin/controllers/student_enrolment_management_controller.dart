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

  Future<void> approveEnrollment(String enrollmentId) async {
    await repository.updateEnrollmentStatus(
      enrollmentId: enrollmentId,
      status: 'approved',
    );
  }

  Future<void> rejectEnrollment(String enrollmentId) async {
    await repository.updateEnrollmentStatus(
      enrollmentId: enrollmentId,
      status: 'rejected',
    );
  }
}
