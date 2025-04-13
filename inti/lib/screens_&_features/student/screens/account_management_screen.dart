import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/utils/color.dart';
import 'package:inti/common/utils/utils.dart';
import 'package:inti/common/widgets/drawer_list.dart';
import 'package:inti/common/widgets/error.dart';
import 'package:inti/common/widgets/loader.dart';
import 'package:inti/screens_&_features/student/controller/payment_controller.dart';

class AccountManagementScreen extends ConsumerStatefulWidget {
  static const routeName = '/account-management-screen';
  final String uid;

  AccountManagementScreen({required this.uid});

  @override
  ConsumerState<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState
    extends ConsumerState<AccountManagementScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  var firebaseAuth = FirebaseAuth.instance.currentUser?.uid;
  var userData = {};
  var userPaymentData = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getData();
    getPaymentRecord();
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

  void getPaymentRecord() async {
    setState(() {
      isLoading = true;
    });

    try {
      // First check if userData is loaded
      if (userData.isEmpty || userData['email'] == null) {
        // If userData is not ready, wait briefly and try again
        await Future.delayed(Duration(milliseconds: 500));
        if (mounted) {
          getPaymentRecord();
        }
        return;
      }

      // Ensure that userData is already loaded. If userData is not yet available,
      // you may call this after getData() is complete.
      if (userData.isNotEmpty && userData['email'] != null) {
        var querySnapshot =
            await FirebaseFirestore.instance
                .collection('user_payment_record')
                .where('primaryEmail', isEqualTo: userData['email'])
                .limit(1)
                .get();

        if (querySnapshot.docs.isNotEmpty) {
          setState(() {
            userPaymentData = querySnapshot.docs.first.data();
          });
        }
      }
    } catch (e) {
      showSnackBar(context, e.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget dialogBoxSelection(String title, VoidCallback onTap) {
    final height = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        height: height * .25,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 5,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Future<void> _showEditPaymentProfileDialog() async {
    final addressController = TextEditingController(
      text: userPaymentData['address'] ?? '',
    );
    final postCodeController = TextEditingController(
      text: userPaymentData['postcode']?.toString() ?? '',
    );
    final countryController = TextEditingController(
      text: userPaymentData['country'] ?? '',
    );
    final primaryEmailController = TextEditingController(
      text: userData['email'] ?? '',
    );
    final alternativeEmailController = TextEditingController(
      text: userPaymentData['alternativeEmail'] ?? '',
    );
    final emergencyContactNameController = TextEditingController(
      text: userPaymentData['emergencyContactName'] ?? '',
    );
    final emergencyContactNumberController = TextEditingController(
      text: userPaymentData['emergencyContactNumber'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update your payment account profile'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                    controller: postCodeController,
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
                    initialSelection: 'US',
                    showCountryOnly: false,
                    showFlag: true,
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
                    enabled: false,
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
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    final paymentId = userPaymentData['paymentId'];

                    if (paymentId == null) {
                      showSnackBar(context, 'Payment ID is missing');
                      return;
                    }

                    await ref
                        .read(paymentControllerProvider)
                        .updateUserPaymentDetails(
                          paymentId: paymentId,
                          address: addressController.text,
                          postcode: int.parse(postCodeController.text),
                          country: countryController.text,
                          alternativeEmail: alternativeEmailController.text,
                          emergencyContactName:
                              emergencyContactNameController.text,
                          emergencyContactNumber:
                              emergencyContactNumberController.text,
                        );
                    Navigator.of(context).pop();
                    showSnackBar(
                      context,
                      'Payment profile updated successfully',
                    );
                  } catch (e) {
                    print('$e');
                    showSnackBar(
                      context,
                      'Failed to update payment profile: $e',
                    );
                  }
                }
              },
              child: Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentAsync = ref.watch(updateDetailsStreamProvider);

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
            Navigator.pushNamed(context, '/student-home-screen');
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
              : Padding(
                padding: const EdgeInsets.all(25),
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        userData.isNotEmpty && userData['username'] != null
                            ? '${userData['username']}, welcome to Account Management section'
                            : 'No text to show.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        userData.isNotEmpty && userData['username'] != null
                            ? 'Manage your account safely and efficiency'
                            : 'No text to show',
                        style: TextStyle(
                          fontWeight: FontWeight.w300,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 50),

                      Expanded(
                        child: paymentAsync.when(
                          loading: () => Center(child: Loader()),
                          error: (error, stackTrace) {
                            print('Error message: $error');
                            return ErrorScreen(error: '$error');
                          },

                          data: (payment) {
                            if (payment.isEmpty) {
                              return Center(child: Text('No payments found'));
                            }

                            return Padding(
                              padding: EdgeInsets.all(25),
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 20),
                                width: double.infinity,
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      blurRadius: 5,
                                      offset: Offset(2, 2),
                                    ),
                                  ],
                                ),
                                child: SingleChildScrollView(
                                  child: DataTable(
                                    columns: [
                                      DataColumn(label: Text('Payment ID')),
                                      DataColumn(label: Text('Primary Email')),
                                      DataColumn(label: Text('Country')),
                                      DataColumn(label: Text('Postcode')),
                                      DataColumn(
                                        label: Text('Account Balance'),
                                      ),
                                      DataColumn(
                                        label: Text('Emergency Contact Name'),
                                      ),
                                      DataColumn(label: Text('Edit Button')),
                                    ],
                                    rows:
                                        payment.map((payment) {
                                          return DataRow(
                                            cells: [
                                              DataCell(Text(payment.paymentId)),
                                              DataCell(
                                                Text(payment.primaryEmail),
                                              ),
                                              DataCell(Text(payment.country)),
                                              DataCell(
                                                Text(
                                                  payment.postcode.toString(),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  payment.savingsAccount
                                                      .toString(),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  payment.emergencyContactName,
                                                ),
                                              ),
                                              DataCell(
                                                ElevatedButton(
                                                  onPressed:
                                                      _showEditPaymentProfileDialog,
                                                  child: Text('Edit'),
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
