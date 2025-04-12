import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/utils/color.dart';
import 'package:inti/common/utils/utils.dart';
import 'package:inti/common/widgets/drawer_list.dart';
import 'package:inti/common/widgets/loader.dart';
import 'package:inti/models/payment_record.dart';
import 'package:inti/screens_&_features/student/controller/payment_controller.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  static const routeName = '/payment-screen';
  final String uid;

  const PaymentScreen({Key? key, required this.uid}) : super(key: key);

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  var firebaseAuth = FirebaseAuth.instance.currentUser?.uid;
  bool isLoading = false;
  Map<String, dynamic> userData = {};
  PaymentRecord? paymentRecord;
  String? paymentId;

  // Constants
  static const double feeAmount = 3500.0;
  static const double lowBalanceThreshold = 5000.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get user data
      await _getUserData();

      // Check if user has payment record
      if (userData.containsKey('email')) {
        await _checkAndFetchPaymentRecord();
      }
    } catch (e) {
      showSnackBar(context, e.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _getUserData() async {
    try {
      var userSnap =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.uid)
              .get();

      if (userSnap.exists) {
        setState(() {
          userData = userSnap.data() ?? {};
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
      throw Exception("Failed to load user data");
    }
  }

  Future<void> _checkAndFetchPaymentRecord() async {
    try {
      final email = userData['email'] as String?;
      if (email == null) return;

      // Get payment record by email
      PaymentRecord? record = await ref
          .read(paymentControllerProvider)
          .getPaymentRecordByEmail(email);

      // If record exists, update state
      if (record != null) {
        setState(() {
          paymentRecord = record;
          paymentId = record.paymentId;
        });
      } else {
        // If no record, show dialog for first-time user
        if (mounted) {
          Future.delayed(Duration.zero, () => _showInitialPaymentDialog());
        }
      }
    } catch (e) {
      print("Error checking payment record: $e");
      throw Exception("Failed to check payment status");
    }
  }

  // Dialog for collecting payment info from first-time users
  void _showInitialPaymentDialog() async {
    final addressController = TextEditingController();
    final postcodeController = TextEditingController();
    final countryController = TextEditingController();
    final primaryEmailController = TextEditingController(
      text: userData['email'] ?? '',
    );
    final alternativeEmailController = TextEditingController();
    final emergencyContactNameController = TextEditingController();
    final emergencyContactNumberController = TextEditingController();
    final savingsController = TextEditingController(); // For initial savings

    showDialog(
      context: context,
      barrierDismissible: false, // Force user to fill form
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Welcome! Setup Your Payment Account'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'As a first-time user, please provide your payment information:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Address is required'
                                : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: postcodeController,
                    decoration: InputDecoration(
                      labelText: 'Postcode',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Postcode is required'
                                : null,
                  ),
                  SizedBox(height: 12),
                  CountryCodePicker(
                    onChanged: (country) {
                      countryController.text = country.name ?? '';
                    },
                    initialSelection: 'US', // Set default country code
                    showCountryOnly: false,
                    showFlag:
                        true, // Ensure this is set to true // Ensure this is true to display flags
                    showOnlyCountryWhenClosed: true,
                    searchDecoration: InputDecoration(
                      labelText: 'Search Country',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: primaryEmailController,
                    decoration: InputDecoration(
                      labelText: 'Primary Email',
                      border: OutlineInputBorder(),
                    ),
                    enabled: false, // Use email from user data
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Email is required'
                                : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: alternativeEmailController,
                    decoration: InputDecoration(
                      labelText: 'Alternative Email (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: emergencyContactNameController,
                    decoration: InputDecoration(
                      labelText: 'Emergency Contact Name',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Emergency contact name is required'
                                : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: emergencyContactNumberController,
                    decoration: InputDecoration(
                      labelText: 'Emergency Contact Number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Emergency contact number is required'
                                : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: savingsController,
                    decoration: InputDecoration(
                      labelText: 'Initial Savings Amount (RM)',
                      border: OutlineInputBorder(),
                      hintText: 'Minimum recommended: $feeAmount',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Initial amount is required';
                      }
                      try {
                        double amount = double.parse(value);
                        if (amount < feeAmount) {
                          return 'Amount should be at least \$$feeAmount';
                        }
                      } catch (e) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    // Create payment record
                    String id = await ref
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

                    // Update state with new payment record
                    setState(() {
                      paymentId = id;
                    });

                    // Refresh payment record
                    await _checkAndFetchPaymentRecord();

                    // Close dialog
                    Navigator.of(context).pop();
                  } catch (e) {
                    // Error handled in controller
                  }
                }
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  // Process payment
  Future<void> _processPayment() async {
    if (paymentRecord == null || paymentId == null) {
      showSnackBar(context, 'No payment record found');
      return;
    }

    // Check if payment is approved
    if (paymentRecord!.status != 'approved') {
      showSnackBar(context, 'Your payment record is not yet approved by admin');
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Confirm Payment'),
            content: Text('Do you want to process a payment of \$$feeAmount?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    await ref
                        .read(paymentControllerProvider)
                        .processPayment(
                          paymentId: paymentId!,
                          feeAmount: feeAmount,
                          context: context,
                        );

                    // Refresh payment record
                    await _checkAndFetchPaymentRecord();

                    // Check if balance is low after payment
                    if (paymentRecord != null &&
                        paymentRecord!.savingsAccount < lowBalanceThreshold) {
                      _showLowBalanceDialog();
                    }
                  } catch (e) {
                    // Error handled in controller
                  }
                },
                child: Text('Confirm'),
              ),
            ],
          ),
    );
  }

  // Show dialog for low balance
  void _showLowBalanceDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Low Balance Alert'),
            content: Text(
              'Your savings account balance is low. Please reload your account for future payments.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Later'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showReloadDialog();
                },
                child: Text('Reload Now'),
              ),
            ],
          ),
    );
  }

  // Show dialog to reload funds
  void _showReloadDialog() {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Reload Savings Account'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Enter amount to add to your savings account:'),
                SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount (RM)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    double amount = double.parse(amountController.text);
                    if (amount <= 0) {
                      showSnackBar(context, 'Please enter a valid amount');
                      return;
                    }

                    Navigator.of(context).pop();

                    if (paymentId != null) {
                      await ref
                          .read(paymentControllerProvider)
                          .reloadSavingsAccount(
                            paymentId: paymentId!,
                            amount: amount,
                            context: context,
                          );

                      // Refresh payment record
                      await _checkAndFetchPaymentRecord();
                    }
                  } catch (e) {
                    showSnackBar(context, 'Please enter a valid number');
                  }
                },
                child: Text('Reload'),
              ),
            ],
          ),
    );
  }

  // Helper method to build status chip
  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor = Colors.white;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        chipColor = Colors.orange;
        icon = Icons.pending;
        break;
      case 'approved':
        chipColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        chipColor = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        chipColor = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 16),
          SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Helper method to build detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: TextStyle(
                color: value.isEmpty ? Colors.grey : Colors.black,
              ),
            ),
          ),
        ],
      ),
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
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header
                      Text(
                        userData.isNotEmpty && userData['username'] != null
                            ? '${userData['username']}, Welcome to Payment Section'
                            : 'Welcome to Payment Section',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 30),

                      // Payment status card
                      paymentRecord != null
                          ? Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Payment Account',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Divider(thickness: 1),
                                SizedBox(height: 10),

                                // Account details
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Current Balance:'),
                                    Text(
                                      '\$${paymentRecord!.savingsAccount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color:
                                            paymentRecord!.savingsAccount <
                                                    lowBalanceThreshold
                                                ? Colors.red
                                                : Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Status:'),
                                    _buildStatusChip(paymentRecord!.status),
                                  ],
                                ),
                                SizedBox(height: 20),

                                // Action buttons
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed:
                                          paymentRecord!.status == 'approved'
                                              ? _processPayment
                                              : null,
                                      icon: Icon(Icons.payment),
                                      label: Text('Pay Fee (\$$feeAmount)'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _showReloadDialog(),
                                      icon: Icon(Icons.account_balance_wallet),
                                      label: Text('Reload'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Status info
                                if (paymentRecord!.status == 'pending') ...[
                                  Padding(
                                    padding: const EdgeInsets.only(top: 20),
                                    child: Container(
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.yellow.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.yellow.shade700,
                                        ),
                                      ),
                                      child: Text(
                                        'Your payment account is pending approval from the administrator. '
                                        'You cannot process payments until it is approved.',
                                        style: TextStyle(
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                          : Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'No Payment Account Found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Please set up your payment account to continue.',
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () => _showInitialPaymentDialog(),
                                  child: Text('Set Up Payment Account'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                      SizedBox(height: 30),

                      // Payment details
                      if (paymentRecord != null) ...[
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Account Details',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Divider(thickness: 1),
                              SizedBox(height: 10),
                              _buildDetailRow(
                                'Email',
                                paymentRecord!.primaryEmail,
                              ),
                              _buildDetailRow(
                                'Alt Email',
                                paymentRecord!.alternativeEmail,
                              ),
                              _buildDetailRow(
                                'Address',
                                paymentRecord!.address,
                              ),
                              _buildDetailRow(
                                'Postcode',
                                paymentRecord!.postcode.toString(),
                              ),
                              _buildDetailRow(
                                'Country',
                                paymentRecord!.country,
                              ),
                              _buildDetailRow(
                                'Emergency Contact',
                                '${paymentRecord!.emergencyContactName} (${paymentRecord!.emergencyContactNumber})',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
    );
  }
}
