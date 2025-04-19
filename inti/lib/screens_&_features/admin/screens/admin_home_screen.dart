import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/utils/color.dart';
import 'package:inti/common/utils/utils.dart';
import 'package:inti/common/widgets/drawer_list.dart';
import 'package:inti/common/widgets/error.dart';
import 'package:inti/common/widgets/loader.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  static const routeName = '/admin-home-screen';
  final String uid;

  const AdminHomeScreen({super.key, required this.uid});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  var firebaseAuth = FirebaseAuth.instance.currentUser?.uid;
  var userData = {};
  bool isLoading = false;

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

  Widget courseSummary(String title, Future<int> quantityFuture) {
    final height = MediaQuery.of(context).size.height;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Container(
          height: height * .3,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1.5, // Border width
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3), // Shadow color
                blurRadius: 5, // Blur radius
                offset: Offset(2, 2), // Shadow offset
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: textColor,
                  ),
                ),

                SizedBox(height: 10),

                // must be a dynamic data
                FutureBuilder(
                  future: quantityFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Loader();
                    } else if (snapshot.hasError) {
                      return ErrorScreen(error: snapshot.error.toString());
                    } else {
                      return Text(
                        snapshot.data.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.w300,
                          fontSize: 15,
                          color: textColor,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<int> getTotalCourses() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('admin_add_courses')
              .get();
      return snapshot.docs.length;
      // Return the total number of documents in the collection
    } catch (e) {
      print('Error fetching total courses: $e');
      return 0; // Return 0 in case of an error
    }
  }

  Future<int> getTotalStudents() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'student')
              .get();

      if (snapshot.docs.isEmpty) {
        print('No students found in the database.');
      }

      return snapshot.docs.length;
    } catch (e) {
      print('Error fetching total students: $e');
      return 0; // Return 0 in case of an error
    }
  }

  Future<int> getTotalAdmins() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'admin')
              .get();

      if (snapshot.docs.isEmpty) {
        print('No admins found in the database.');
      }

      return snapshot.docs.length;
    } catch (e) {
      print('Error fetching total admins: $e');
      return 0;
    }
  }

  Future<int> getTotalDropRequests() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('drop_requests')
              .where('status', isEqualTo: 'pending')
              .get();

      if (snapshot.docs.isEmpty) {
        print('No drop requests found in the database.');
      }

      return snapshot.docs.length;
    } catch (e) {
      print('Error fetching total drop requests: $e');
      return 0;
    }
  }

  Future<int> getTotalPaymentRequests() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('user_payment_record')
              .where('status', isEqualTo: 'pending')
              .get();

      if (snapshot.docs.isEmpty) {
        print('No payment requests found in the database.');
      }

      return snapshot.docs.length;
    } catch (e) {
      print('Error fetching total payment requests: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

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
            // BACKGROUND IMAGE
            Container(
              color: Colors.transparent,
              width: double.infinity,
              height: height * .7,
              child: Image.asset('images/civic_typer.jpg', fit: BoxFit.cover),
            ),

            SizedBox(height: 30),

            // TITLE WITH CONTAINER
            Padding(
              padding: const EdgeInsets.all(25),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1.5, // Border width
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3), // Shadow color
                      blurRadius: 5, // Blur radius
                      offset: Offset(2, 2), // Shadow offset
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Text(
                  userData.isNotEmpty && userData['username'] != null
                      ? 'Welcome to admin home screen, ${userData['username']}'
                      : 'Unknown user',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                    color: textColor,
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),

            // SUMMARY OF COURSE DETAILS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                courseSummary('Total Course(s)', getTotalCourses()),
                courseSummary(
                  'Pending drop request(s)',
                  getTotalDropRequests(),
                ),
                courseSummary(
                  'Payment pending request(s)',
                  getTotalPaymentRequests(),
                ),
                courseSummary('Total Student(s)', getTotalStudents()),
                courseSummary('Total Admin(s)', getTotalAdmins()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
