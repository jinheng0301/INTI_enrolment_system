import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/models/payment_record.dart';

final paymentVerificationRepositoryProvider = Provider(
  (ref) => PaymentVerificationRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  ),
);

class PaymentVerificationRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  PaymentVerificationRepository({required this.firestore, required this.auth});

  // Process payment approval/rejection
  Future<void> processPaymentApproval({
    required String paymentId,
    required bool approved,
  }) async {
    try {
      await firestore.collection('user_payment_record').doc(paymentId).update({
        'status': approved ? 'approved' : 'rejected',
        'processedDate': FieldValue.serverTimestamp(),
        'processedBy': auth.currentUser?.uid ?? 'unknown',
      });
      print(
        "✅ Payment record $paymentId processed as ${approved ? 'approved' : 'rejected'}",
      );
    } catch (e) {
      print("❌ Error processing payment approval: $e");
      throw Exception('Failed to process payment approval: $e');
    }
  }

  // A stream to fetch all payment records with pending status (for admin)
  Stream<List<PaymentRecord>> getPendingPayments() {
    return firestore
        .collection('user_payment_record')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            var data = doc.data();
            // If paymentId isn't already in the data, add document ID as paymentId
            if (!data.containsKey('paymentId')) {
              data['paymentId'] = doc.id;
            }
            return PaymentRecord.fromMap(data);
          }).toList();
        });
  }

  // Get payment details for a specific ID
  Future<PaymentRecord?> getPaymentDetails(String paymentId) async {
    try {
      DocumentSnapshot doc =
          await firestore
              .collection('user_payment_record')
              .doc(paymentId)
              .get();

      if (doc.exists) {
        return PaymentRecord.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print("❌ Error fetching payment details: $e");
      throw Exception('Failed to fetch payment details: $e');
    }
  }
}
