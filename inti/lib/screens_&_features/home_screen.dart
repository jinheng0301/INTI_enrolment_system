import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/utils/color.dart';
import 'package:inti/common/utils/utils.dart';
import 'package:inti/common/widgets/drawer_list.dart';

class HomeScreen extends ConsumerStatefulWidget {
  static const routeName = '/home-screen';
  final String uid;

  HomeScreen({required this.uid});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // ✅ Add a key
  var firebaseAuth = FirebaseAuth.instance.currentUser?.uid;
  var userData = {};
  bool isLoading = false;
  late String programme;
  late String semester;
  DateTime currentTime = DateTime.now();

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

  Column buildPaymentColumn(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.red,
          ),
        ),

        SizedBox(height: 5),

        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 18,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      key: _scaffoldKey, // ✅ Assign the scaffold key

      drawer: DrawerList(uid: firebaseAuth ?? ''), // ✅ Add the drawer

      appBar: AppBar(
        backgroundColor: tabColor,
        toolbarHeight: 80,
        leading: IconButton(
          // ✅ Add a manual menu button
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Image.asset(
          'images/inti_logo.png',
          height: 40,
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // BANNER AND TITLE
            Container(
              color: Colors.amberAccent,
              width: double.infinity,
              height: height * .5,
              child: Stack(
                children: [
                  Image.asset('images/inti_background.jpg', fit: BoxFit.cover),

                  Positioned(
                    bottom: 10,
                    left: 30,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData.isNotEmpty && userData['username'] != null
                                ? 'Welcome back, ${userData['username']}'
                                : 'Unknown User',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 30,
                              color: textColor,
                            ),
                          ),
                          Text(
                            'Programme: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textColor,
                            ),
                          ),
                          Text(
                            'Semester: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textColor,
                            ),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {},
                            child: Text('Enrolled'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 40),

            // PAYMENT SUMMARY
            Padding(
              padding: const EdgeInsets.all(25),
              child: Container(
                width: double.infinity,
                height: height * .25,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                      Theme.of(context).colorScheme.tertiary,
                    ],
                    transform: GradientRotation(pi / 6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 2,
                      color: Colors.black.withValues(
                        red: 200,
                        green: 200,
                        blue: 300,
                      ),
                      offset: Offset(5, 5),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Payment Summary',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: secondaryColor,
                            ),
                          ),
                          Icon(Icons.monetization_on, color: Colors.white),
                        ],
                      ),

                      SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          buildPaymentColumn('Total Fess', 'RM12,500'),
                          buildPaymentColumn('Paid', 'RM7,500'),
                          buildPaymentColumn('Remaining', 'RM5,000'),
                        ],
                      ),

                      SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Payment due date: $currentTime',
                            style: TextStyle(fontSize: 15),
                          ),
                          ElevatedButton(
                            onPressed: () {},
                            child: Text('Pay now'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 40),

            // ENROLLED COURSES
            Container(color: Colors.blueAccent, height: height * .5),
          ],
        ),
      ),
    );
  }
}
