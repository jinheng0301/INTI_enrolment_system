import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/utils/utils.dart';
import 'package:inti/models/payment_record.dart';
import 'package:inti/screens_&_features/student/repository/payment_repository.dart';

final paymentControllerProvider = Provider((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return PaymentController(repository: repository, ref: ref);
});

final updateDetailsStreamProvider =
    StreamProvider.autoDispose<List<PaymentRecord>>((ref) {
      final userEmail = FirebaseAuth.instance.currentUser?.email;

      // If no logged-in user, return empty list
      if (userEmail == null) {
        return Stream.value([]);
      }

      return FirebaseFirestore.instance
          .collection('user_payment_record')
          .where('primaryEmail', isEqualTo: userEmail)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map((doc) => PaymentRecord.fromMap(doc.data()))
                    .toList(),
          );
    });

class PaymentController {
  final PaymentRepository repository;
  final Ref ref;

  PaymentController({required this.repository, required this.ref});

  // Check if user has a payment record
  Future<bool> hasPaymentRecord(String email) {
    return repository.hasPaymentRecord(email);
  }

  // Get user's payment record
  Future<PaymentRecord?> getPaymentRecordByEmail(String email) {
    return repository.getPaymentRecordByEmail(email);
  }

  Future<String> collectUserPaymentData({
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
      String paymentId = await repository.collectUserPaymentData(
        address: address,
        postcode: postcode,
        country: country,
        primaryEmail: primaryEmail,
        alternativeEmail: alternativeEmail,
        emergencyContactName: emergencyContactName,
        emergencyContactNumber: emergencyContactNumber,
        savingsAccount: savingsAccount,
      );

      showSnackBar(context, 'Successfully collected $primaryEmail data.');
      return paymentId;
    } catch (e) {
      showSnackBar(context, 'Failed to collect payment data: $e');
      throw Exception(e);
    }
  }

  Future<void> updateUserPaymentDetails({
    required String paymentId,
    required String address,
    required int postcode,
    required String country,
    required String alternativeEmail,
    required String emergencyContactName,
    required String emergencyContactNumber,
  }) async {
    try {
      await repository.updateUserPaymentDetails(
        paymentId: paymentId,
        address: address,
        postcode: postcode,
        country: country,
        alternativeEmail: alternativeEmail,
        emergencyContactName: emergencyContactName,
        emergencyContactNumber: emergencyContactNumber,
      );
    } catch (e) {
      print('Failed to update payment deatils: $e');
      throw Exception(e);
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
      throw Exception(e);
    }
  }

  Future<void> reloadSavingsAccount({
    required String paymentId,
    required double amount,
    required BuildContext context,
  }) async {
    try {
      await repository.reloadSavingsAccount(
        paymentId: paymentId,
        amount: amount,
      );
      showSnackBar(
        context,
        'Account reloaded successfully with \$${amount.toStringAsFixed(2)}',
      );
    } catch (e) {
      showSnackBar(context, 'Failed to reload account: $e');
      throw Exception(e);
    }
  }
}
