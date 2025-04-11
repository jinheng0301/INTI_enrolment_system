import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/utils/color.dart';
import 'package:inti/common/utils/utils.dart';
import 'package:inti/common/widgets/drawer_list.dart';
import 'package:inti/models/payment_record.dart';
import 'package:inti/screens_&_features/student/controller/payment_controller.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  static const routeName = '/payment-screen';
  final String uid;

  PaymentScreen({required this.uid});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  var firebaseAuth = FirebaseAuth.instance.currentUser?.uid;
  var userData = {};
  bool isLoading = false;
  PaymentRecord? paymentRecord;

  @override
  void initState() {
    // TODO: implement initState
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

      userData = userSnap.data()!;
    } catch (e) {
      showSnackBar(context, e.toString());
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchPaymentRecord() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('user_payment_record')
              .where('primaryEmail', isEqualTo: userData['email'] ?? '')
              .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          paymentRecord = PaymentRecord.fromMap(snapshot.docs.first.data());
        });
      } else {
        // No payment record exists (first-time user)
        Future.delayed(Duration.zero, () => _showInitialPaymentDialog());
      }
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  /// Dialog to collect initial payment data from a first-time user.
  Future<void> _showInitialPaymentDialog() async {
    final addressController = TextEditingController();
    final postcodeController = TextEditingController();
    final countryController = TextEditingController();
    final primaryEmailController = TextEditingController();
    final alternativeEmailController = TextEditingController();
    final emergencyContactNameController = TextEditingController();
    final emergencyContactNumberController = TextEditingController();
    final savingsController = TextEditingController(); // New field

    return showDialog(
      context: context,
      barrierDismissible: false, // Force user to fill form
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Payment Information'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: addressController,
                    decoration: InputDecoration(labelText: 'Address'),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Enter address'
                                : null,
                  ),
                  TextFormField(
                    controller: postcodeController,
                    decoration: InputDecoration(labelText: 'Postcode'),
                    keyboardType: TextInputType.number,
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Enter postcode'
                                : null,
                  ),
                  TextFormField(
                    controller: countryController,
                    decoration: InputDecoration(labelText: 'Country'),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Enter country'
                                : null,
                  ),
                  TextFormField(
                    controller: primaryEmailController,
                    decoration: InputDecoration(labelText: 'Primary Email'),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Enter email'
                                : null,
                  ),
                  TextFormField(
                    controller: alternativeEmailController,
                    decoration: InputDecoration(labelText: 'Alternative Email'),
                  ),
                  TextFormField(
                    controller: emergencyContactNameController,
                    decoration: InputDecoration(
                      labelText: 'Emergency Contact Name',
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Enter emergency contact name'
                                : null,
                  ),
                  TextFormField(
                    controller: emergencyContactNumberController,
                    decoration: InputDecoration(
                      labelText: 'Emergency Contact Number',
                    ),
                    keyboardType: TextInputType.phone,
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Enter emergency contact number'
                                : null,
                  ),
                  TextFormField(
                    controller: savingsController,
                    decoration: InputDecoration(
                      labelText: 'Initial Savings Amount',
                    ),
                    keyboardType: TextInputType.number,
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Enter savings amount'
                                : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Optionally, you can prevent closing if data is required.
              },
              child: Text('Submit'),
            ),
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await ref
                      .read(paymentControllerProvider)
                      .collectUserPaymentData(
                        address: addressController.text,
                        postcode: int.parse(postcodeController.text),
                        country: countryController.text,
                        primaryEmail: primaryEmailController.text,
                        alternativeEmail: alternativeEmailController.text,
                        emergencyContactName:
                            emergencyContactNameController.text,
                        emergencyContactNumber:
                            emergencyContactNumberController.text,
                        savingsAccount: double.parse(savingsController.text),
                        context: context,
                      );
                  // After saving, re-fetch the payment record.
                  await fetchPaymentRecord();
                  Navigator.of(context).pop();
                }
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  /// Simulated payment processing. This method deducts a fee amount (e.g., 3500)
  /// from the savings account and updates the record. If the remaining savings
  /// fall below a threshold (e.g., 500), it pops a dialog to remind the user.
  void _processPayment() async {
    if (paymentRecord == null) return;
    const feeAmount = 3500.0;
    const threshold = 500.0;

    // For this example, assume the payment record document ID is known.
    // In a real scenario, you might want to store the payment document ID
    // along with paymentRecord. Here, we perform a query:
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance
            .collection('user_payment_record')
            .where('primryEmail', isEqualTo: paymentRecord!.primaryEmail)
            .get();

    if (snapshot.docs.isEmpty) {
      showSnackBar(context, 'Payment record not found!');
      return;
    }
    String paymentId = snapshot.docs.first.id;

    try {
      await ref
          .read(paymentControllerProvider)
          .processPayment(
            paymentId: paymentId,
            feeAmount: feeAmount,
            context: context,
          );
      // Re-fetch updated payment record
      await fetchPaymentRecord();

      // Check remaining savings and show reload dialog if necessary
      if (paymentRecord != null && paymentRecord!.savingsAccount < threshold) {
        _showReloadDialog();
      }
    } catch (e) {
      showSnackBar(context, 'Payment processing failed: $e');
    }
  }

  void _showReloadDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Low savings balance'),
          content: Text(
            'Your savings account balance is low. Please reload your amount for future payments.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Sure!'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,

      drawer: DrawerList(uid: firebaseAuth ?? ''),

      appBar: AppBar(
        backgroundColor: tabColor,
        toolbarHeight: 80,
        leading: IconButton(
          // ✅ Add a manual menu button
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/admin-home-screen');
          },
          child: Image.asset('images/inti_logo.png', height: 40),
        ), // ✅ Adjusted logo
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

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              Text(
                userData.isNotEmpty && userData['username'] != null
                    ? '${userData['username']} student, welcome to payment section.'
                    : 'Unknown user',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 20),

              paymentRecord != null
                  ? Column(
                    children: [
                      Text(
                        'Your current savings balance is: \$${paymentRecord!.savingsAccount.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _processPayment,
                        child: Text('Pay Fee (\$3500)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                      ),
                    ],
                  )
                  : Text('No payment record found'),

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                  // Optionally, user can reload funds by navigating to a fund reloading screen
                  // For this example, we just show a snackbar.
                  showSnackBar(
                    context,
                    'Reload funds functionality coming soon!',
                  );
                },
                child: Text('Reload Funds'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
