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

    return Padding(
      padding: const EdgeInsets.all(25),
      child: Container(
        height: height * .2,
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

            SizedBox(height: 40),

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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                courseSummary('Total Course(s)', getTotalCourses()),
                courseSummary(
                  'Pending Enrolments',
                  Future.value(15),
                ), // Replace with dynamic data if needed
                courseSummary('Payments verified', Future.value(30)),
                courseSummary('New User(s)', Future.value(10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
