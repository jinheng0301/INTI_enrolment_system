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

  // Check if user has a payment record
  Future<bool> hasPaymentRecord(String email) async {
    try {
      final snapshot =
          await firestore
              .collection('user_payment_record')
              .where('primaryEmail', isEqualTo: email)
              .limit(1)
              .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print("❌ Error checking payment record: $e");
      throw Exception('Failed to check payment record: $e');
    }
  }

  // Get user's payment record by email
  Future<PaymentRecord?> getPaymentRecordByEmail(String email) async {
    try {
      final snapshot =
          await firestore
              .collection('user_payment_record')
              .where('primaryEmail', isEqualTo: email)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        return PaymentRecord.fromMap(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print("❌ Error fetching payment record: $e");
      throw Exception('Failed to fetch payment record: $e');
    }
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
  }) async {
    try {
      String paymentId = Uuid().v1();

      PaymentRecord paymentRecord = PaymentRecord(
        paymentId: paymentId,
        address: address,
        postcode: postcode,
        country: country,
        primaryEmail: primaryEmail,
        alternativeEmail: alternativeEmail,
        emergencyContactName: emergencyContactName,
        emergencyContactNumber: emergencyContactNumber,
        savingsAccount: savingsAccount,
        status: 'pending', // Set initial status as pending
      );

      await firestore
          .collection('user_payment_record')
          .doc(paymentId)
          .set(paymentRecord.toMap());

      print('✅ Payment record added successfully: ${paymentRecord.toMap()}');
      return paymentId;
    } catch (e) {
      print("❌ Failed to record payment: $e");
      throw Exception('Failed to record payment: $e');
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
      await firestore.collection('user_payment_record').doc(paymentId).update({
        'address': address,
        'postcode': postcode,
        'country': country,
        'alternativeEmail': alternativeEmail,
        'emergencyContactName': emergencyContactName,
        'emergencyContactNumber': emergencyContactNumber,
      });
    } catch (e) {
      print('Failed to update payment deatils: $e');
    }
  }

  Stream<List<PaymentRecord>> getPayment() {
    try {
      final userEmail = auth.currentUser?.email;

      if (userEmail == null) {
        return Stream.value([]);
      }

      return firestore
          .collection('user_payment_record')
          .where('primaryEmail', isEqualTo: userEmail)
          .snapshots()
          .map((snapshot) {
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

        // Check if payment is approved
        String status = snapshot.get('status') as String;
        if (status != 'approved') {
          throw Exception("Payment not yet approved by admin!");
        }

        double currentAmount =
            (snapshot.get('savingsAccount') as num).toDouble();
        if (currentAmount < feeAmount) {
          throw Exception("Insufficient funds!");
        }

        // Deduct the fee amount
        double updatedAmount = currentAmount - feeAmount;
        transaction.update(paymentDocRef, {
          'savingsAccount': updatedAmount,
          'lastPaymentDate': FieldValue.serverTimestamp(),
        });
      });
      print("✅ Payment processed, fee deducted: $feeAmount");
    } catch (e) {
      print("❌ Error processing payment: $e");
      throw Exception('Failed to process payment: $e');
    }
  }

  // Reload the savings account
  Future<void> reloadSavingsAccount({
    required String paymentId,
    required double amount,
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

        // Add the amount
        double updatedAmount = currentAmount + amount;
        transaction.update(paymentDocRef, {
          'savingsAccount': updatedAmount,
          'lastReloadDate': FieldValue.serverTimestamp(),
        });
      });
      print("✅ Account reloaded, amount added: $amount");
    } catch (e) {
      print("❌ Error reloading account: $e");
      throw Exception('Failed to reload account: $e');
    }
  }
}
