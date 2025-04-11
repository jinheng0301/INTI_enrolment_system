import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/utils/utils.dart';
import 'package:inti/models/payment_record.dart';
import 'package:inti/screens_&_features/student/repository/payment_repository.dart';

final paymentControllerProvider = Provider((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return PaymentController(repository: repository, ref: ref);
});

class PaymentController {
  final PaymentRepository repository;
  final Ref ref;

  PaymentController({required this.repository, required this.ref});

  Future<void> collectUserPaymentData({
    required String address,
    required int postcode,
    required String country,
    required String primaryEmail,
    required String alternativeEmail,
    required String emergencyContactName,
    required String emergencyContactNumber,
    required double savingsAccount,
    required BuildContext context,
  }) async {
    try {
      await repository.collectUserPaymentData(
        address: address,
        postcode: postcode,
        country: country,
        primaryEmail: primaryEmail,
        alternativeEmail: alternativeEmail,
        emergencyContactName: emergencyContactName,
        emergencyContactNumber: emergencyContactNumber,
        savingsAccount: savingsAccount,
      );

      showSnackBar(context, 'Successfully collect $primaryEmail data.');
    } catch (e) {
      showSnackBar(context, 'Failed to collect payment data: $e');
    }
  }

  Stream<List<PaymentRecord>> getPaymentRecords() {
    return repository.getPayment();
  }

  Future<void> processPayment({
    required String paymentId,
    required double feeAmount,
    required BuildContext context,
  }) async {
    try {
      await repository.processPayment(
        paymentId: paymentId,
        feeAmount: feeAmount,
      );
      showSnackBar(context, 'Payment processed successfully!');
    } catch (e) {
      showSnackBar(context, 'Failed to process payment: $e');
    }
  }
}
