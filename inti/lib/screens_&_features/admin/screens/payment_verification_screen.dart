import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/utils/color.dart';
import 'package:inti/common/utils/utils.dart';
import 'package:inti/common/widgets/drawer_list.dart';
import 'package:inti/common/widgets/error.dart';
import 'package:inti/common/widgets/loader.dart';
import 'package:inti/models/payment_record.dart';
import 'package:inti/screens_&_features/admin/controllers/payment_verification_controller.dart';

class PaymentVerificationScreen extends ConsumerStatefulWidget {
  static const routeName = '/payment-verification-screen';
  final String uid;

  const PaymentVerificationScreen({Key? key, required this.uid})
    : super(key: key);

  @override
  ConsumerState<PaymentVerificationScreen> createState() =>
      _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState
    extends ConsumerState<PaymentVerificationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  var userData = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getData();
  }

  void getData() async {
    setState(() {
      isLoading = true;
    });

    try {
      var userSnap =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.uid)
              .get();

      if (userSnap.exists) {
        setState(() {
          userData = userSnap.data()!;
        });
      }
    } catch (e) {
      showSnackBar(context, e.toString());
    }

    setState(() {
      isLoading = false;
    });
  }

  void _showPaymentDetails(PaymentRecord payment) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Payment Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _detailRow('ID', payment.paymentId),
                  _detailRow('Email', payment.primaryEmail),
                  _detailRow('Address', payment.address),
                  _detailRow('Postcode', payment.postcode.toString()),
                  _detailRow('Country', payment.country),
                  _detailRow('Alt. Email', payment.alternativeEmail),
                  _detailRow('Emergency Contact', payment.emergencyContactName),
                  _detailRow(
                    'Emergency Number',
                    payment.emergencyContactNumber,
                  ),
                  _detailRow(
                    'Savings Account',
                    '\$${payment.savingsAccount.toStringAsFixed(2)}',
                  ),
                  _detailRow('Status', payment.status),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close'),
              ),
              if (payment.status == 'pending')
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _processApproval(payment.paymentId, false);
                      },
                      child: Text(
                        'Reject',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _processApproval(payment.paymentId, true);
                      },
                      child: Text(
                        'Approve',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
            ],
          ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _processApproval(String paymentId, bool approved) async {
    try {
      await ref
          .read(paymentVerificationControllerProvider)
          .processPaymentApproval(
            paymentId: paymentId,
            approved: approved,
            context: context,
          );
    } catch (e) {
      // Error already handled in controller
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingPaymentsAsync = ref.watch(pendingPaymentsProvider);

    return Scaffold(
      key: _scaffoldKey,
      drawer: DrawerList(uid: FirebaseAuth.instance.currentUser?.uid ?? ''),
      appBar: AppBar(
        backgroundColor: tabColor,
        toolbarHeight: 80,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/admin-home-screen');
          },
          child: Image.asset('images/inti_logo.png', height: 40),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.notifications, color: Colors.yellow),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.person, color: Colors.yellow),
          ),
        ],
      ),
      body:
          isLoading
              ? Center(child: Loader())
              : Column(
                children: [
                  // Admin Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            blurRadius: 5,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            userData.isNotEmpty && userData['username'] != null
                                ? '${userData['username']} Admin Panel'
                                : 'Admin Payment Panel',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              color: textColor,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Manage and view pending payment records',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Pending Payments List
                  Expanded(
                    child: pendingPaymentsAsync.when(
                      loading: () => Center(child: Loader()),
                      error:
                          (error, stack) =>
                              ErrorScreen(error: error.toString()),
                      data: (payments) {
                        if (payments.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 64,
                                  color: Colors.green,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No pending payment records',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'All payment records have been processed',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                child: Text(
                                  'Pending Payments (${payments.length})',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: payments.length,
                                  itemBuilder: (context, index) {
                                    final payment = payments[index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 16,
                                      ),
                                      elevation: 2,
                                      child: ListTile(
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        title: Text(
                                          payment.primaryEmail,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(height: 4),
                                            Text(
                                              'Savings: \$${payment.savingsAccount.toStringAsFixed(2)}',
                                            ),
                                            Text(
                                              'Address: ${payment.address}, ${payment.country}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              tooltip: 'View Details',
                                              icon: Icon(
                                                Icons.visibility,
                                                color: Colors.blue,
                                              ),
                                              onPressed:
                                                  () => _showPaymentDetails(
                                                    payment,
                                                  ),
                                            ),
                                            IconButton(
                                              tooltip: 'Reject',
                                              icon: Icon(
                                                Icons.close,
                                                color: Colors.red,
                                              ),
                                              onPressed:
                                                  () => _processApproval(
                                                    payment.paymentId,
                                                    false,
                                                  ),
                                            ),
                                            IconButton(
                                              tooltip: 'Approve',
                                              icon: Icon(
                                                Icons.check,
                                                color: Colors.green,
                                              ),
                                              onPressed:
                                                  () => _processApproval(
                                                    payment.paymentId,
                                                    true,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        isThreeLine: true,
                                        onTap:
                                            () => _showPaymentDetails(payment),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}
