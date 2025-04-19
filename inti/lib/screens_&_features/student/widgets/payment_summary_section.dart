import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:inti/common/widgets/error.dart';
import 'package:inti/common/widgets/loader.dart';
import 'package:intl/intl.dart';

class PaymentSummarySection extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;
  final DateTime paymentDueDate;

  PaymentSummarySection({
    required this.userId,
    required this.userData,
    required this.paymentDueDate,
  });

  @override
  State<PaymentSummarySection> createState() => _PaymentSummarySectionState();
}

class _PaymentSummarySectionState extends State<PaymentSummarySection> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get savings account balance
  Future<double> getSavingsAccountBalance() async {
    try {
      // First get the current user's email from their user document
      var userDoc =
          await _firestore.collection('users').doc(widget.userId).get();
      String userEmail = userDoc.data()?['email'] ?? '';

      // Query by primaryEmail as per security rules
      var querySnapshot =
          await _firestore
              .collection('user_payment_record')
              .where('primaryEmail', isEqualTo: userEmail)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        return (querySnapshot.docs.first.data()['savingsAccount'] ?? 0.0)
            .toDouble();
      }

      return 0.0;
    } catch (e) {
      print('Error fetching savings balance: $e');
      return 0.0;
    }
  }

  // Get total paid amount
  Future<double> getTotalPaidAmount() async {
    try {
      // First get the current user's email
      var userDoc =
          await _firestore.collection('users').doc(widget.userId).get();
      String userEmail = userDoc.data()?['email'] ?? '';

      // Find the payment record ID using email
      var paymentRecordQuery =
          await _firestore
              .collection('user_payment_record')
              .where('primaryEmail', isEqualTo: userEmail)
              .limit(1)
              .get();

      if (paymentRecordQuery.docs.isEmpty) {
        print('No payment record found for this user');
        return 0.0;
      }

      String paymentId = paymentRecordQuery.docs.first.id;

      // Query transactions using paymentId to match security rules
      var transactionsQuery = _firestore
          .collection('payment_transactions')
          .where('paymentId', isEqualTo: paymentId)
          .where('type', isEqualTo: 'payment');

      var transactionsSnapshot = await transactionsQuery.get();

      // Sum up all transaction amounts
      double totalPaid = 0.0;
      for (var doc in transactionsSnapshot.docs) {
        if (doc.data().containsKey('amount')) {
          totalPaid += (doc.data()['amount'] ?? 0.0).toDouble();
        }
      }

      return totalPaid;
    } catch (e) {
      print('Error fetching total paid: $e');
      return 0.0;
    }
  }

  // Get remaining balance to be paid
  Future<double> getRemainingBalance() async {
    const double totalFee = 12500.0; // Example total fee for the semester
    final double paidAmount = await getTotalPaidAmount();
    return totalFee - paidAmount;
  }

  // Widget to display payment data
  Widget buildPaymentColumn(String title, Future<double> paymentFuture) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 8),

        FutureBuilder<double>(
          future: paymentFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Loader();
            } else if (snapshot.hasError) {
              return ErrorScreen(error: snapshot.hasError.toString());
            } else {
              return Text(
                'RM ${snapshot.data?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
                Theme.of(context).colorScheme.tertiary,
              ],
              transform: GradientRotation(pi / 6),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Payment Summary',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                const Divider(color: Colors.white30, thickness: 1),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildPaymentColumn(
                      'Total Saving Account Balances',
                      getSavingsAccountBalance(),
                    ),
                    buildPaymentColumn('Paid', getTotalPaidAmount()),
                    buildPaymentColumn('Remaining', getRemainingBalance()),
                  ],
                ),

                const SizedBox(height: 20),

                const Divider(color: Colors.white30, thickness: 1),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payment due: ${DateFormat('dd MMM yyyy').format(widget.paymentDueDate)}',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          '/payment-screen',
                        );
                      },
                      icon: const Icon(Icons.payment),
                      label: const Text('Pay Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
