import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/models/payment_record.dart';
import 'package:uuid/uuid.dart';

final paymentRepositoryProvider = Provider(
  (ref) => PaymentRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  ),
);

class PaymentRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  PaymentRepository({required this.firestore, required this.auth});

  Future<void> collectUserPaymentData({
    required String address,
    required int postcode,
    required String country,
    required String primaryEmail,
    required String alternativeEmail,
    required String emergencyContactName,
    required String emergencyContactNumber,
    required double savingsAccount,
  }) async {
    try {
      String paymentId = Uuid().v1();

      PaymentRecord paymentRecord = PaymentRecord(
        address: address,
        postcode: postcode,
        country: country,
        primaryEmail: primaryEmail,
        alternativeEmail: alternativeEmail,
        emergencyContactName: emergencyContactName,
        emergencyContactNumber: emergencyContactNumber,
        savingsAccount: savingsAccount,
      );

      await firestore
          .collection('user_payment_record')
          .doc(paymentId)
          .set(paymentRecord.toMap());

      print('✅ Payment record added successfully: ${paymentRecord.toMap()}');
    } catch (e) {
      print("❌ Failed to record payment: $e");
      throw Exception('Failed to record payment: $e');
    }
  }

  Stream<List<PaymentRecord>> getPayment() {
    try {
      return firestore.collection('user_payment_record').snapshots().map((
        snapshot,
      ) {
        return snapshot.docs.map((doc) {
          return PaymentRecord.fromMap(doc.data());
        }).toList();
      });
    } catch (e) {
      print("Error in getPayment stream: $e");
      return Stream.error('Failed to fetch payment records: $e');
    }
  }

  // Process a fee payment and update the savings account (deduct fee)
  Future<void> processPayment({
    required String paymentId,
    required double feeAmount,
  }) async {
    try {
      DocumentReference paymentDocRef = firestore
          .collection('user_payment_record')
          .doc(paymentId);

      await firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(paymentDocRef);

        if (!snapshot.exists) {
          throw Exception("Payment record does not exist!");
        }

        double currentAmount =
            (snapshot.get('savingsAccount') as num).toDouble();
        if (currentAmount < feeAmount) {
          throw Exception("Insufficient funds!");
        }

        // Deduct the fee amount
        double updatedAmount = currentAmount - feeAmount;
        transaction.update(paymentDocRef, {'savingsAccount': updatedAmount});
      });
      print("✅ Payment processed, fee deducted: $feeAmount");
    } catch (e) {
      print("❌ Error processing payment: $e");
      throw Exception('Failed to process payment: $e');
    }
  }
}
