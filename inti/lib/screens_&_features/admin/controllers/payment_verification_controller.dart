import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/utils/utils.dart';
import 'package:inti/models/payment_record.dart';
import 'package:inti/screens_&_features/admin/repositories/payment_verification_repository.dart';

final paymentVerificationControllerProvider = Provider((ref) {
  final repository = ref.watch(paymentVerificationRepositoryProvider);
  return PaymentVerificationController(repository: repository, ref: ref);
});

// Provider for streaming pending payments
final pendingPaymentsProvider = StreamProvider<List<PaymentRecord>>((ref) {
  final repository = ref.watch(paymentVerificationRepositoryProvider);
  return repository.getPendingPayments();
});

class PaymentVerificationController {
  final PaymentVerificationRepository repository;
  final Ref ref;

  PaymentVerificationController({required this.repository, required this.ref});

  Future<void> processPaymentApproval({
    required String paymentId,
    required bool approved,
    required BuildContext context,
  }) async {
    try {
      await repository.processPaymentApproval(
        paymentId: paymentId,
        approved: approved,
      );
      showSnackBar(
        context,
        approved ? 'Payment approved.' : 'Payment rejected.',
      );
    } catch (e) {
      showSnackBar(context, 'Failed to process payment approval: $e');
      throw Exception(e);
    }
  }

  // Get pending payments for admin view
  Stream<List<PaymentRecord>> getPendingPayments() {
    return repository.getPendingPayments();
  }

  // Get payment details for a specific payment
  Future<PaymentRecord?> getPaymentDetails(String paymentId) {
    return repository.getPaymentDetails(paymentId);
  }
}
