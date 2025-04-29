import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/utils/color.dart';
import 'package:inti/common/utils/utils.dart';
import 'package:inti/common/widgets/drawer_list.dart';
import 'package:inti/screens_&_features/admin/widgets/build_quick_action_tile.dart';
import 'package:inti/screens_&_features/admin/widgets/course_summary.dart';
import 'package:intl/intl.dart';

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
  String greeting = 'Good morning';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getData();
    _setGreeting();
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

  void _setGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good night';
    }
  }

  Widget welcomeHeader() {
    return Container(
      margin: const EdgeInsets.all(25),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tabColor, tabColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: tabColor.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userData.isNotEmpty && userData['username'] != null
                        ? 'Mr. ${userData['username']} Admin'
                        : 'Administrator',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(DateTime.now()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final width = MediaQuery.of(context).size.width;

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

            welcomeHeader(),

            // SUMMARY OF COURSE DETAILS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Wrap(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      courseSummary(
                        title: 'Total Course(s)',
                        quantityFuture: getTotalCourses(),
                        icon: Icons.book,
                        color: Colors.blue,
                      ),
                      courseSummary(
                        title: 'Pending drop request(s)',
                        quantityFuture: getTotalDropRequests(),
                        icon: Icons.assignment_late,
                        color: Colors.orange,
                      ),
                      courseSummary(
                        title: 'Payment pending request(s)',
                        quantityFuture: getTotalPaymentRequests(),
                        icon: Icons.payment,
                        color: Colors.green,
                      ),
                      courseSummary(
                        title: 'Total Student(s)',
                        quantityFuture: getTotalStudents(),
                        icon: Icons.school,
                        color: Colors.purple,
                      ),
                      courseSummary(
                        title: 'Total Admin(s)',
                        quantityFuture: getTotalAdmins(),
                        icon: Icons.admin_panel_settings,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // QUCIK ACTIONS SECTION
            Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(25),
              child: Container(
                width: width * .6,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    buildQuickActionTile(
                      color: Colors.blue,
                      icon: Icons.edit_note,
                      subtitle: 'Add or modify course details',
                      title: 'Manage Courses',
                      onTap:
                          () => Navigator.pushNamed(
                            context,
                            '/manage-course-screen',
                          ),
                    ),
                    buildQuickActionTile(
                      color: Colors.orange,
                      icon: Icons.rule_folder,
                      subtitle: 'Approve or reject student requests',
                      title: 'Review Drop Requests',
                      onTap:
                          () => Navigator.pushNamed(
                            context,
                            '/student-enrolment-management-screen',
                          ),
                    ),
                    buildQuickActionTile(
                      color: Colors.green,
                      icon: Icons.payments,
                      subtitle: 'Add or modify course details',
                      title: 'Process Payments',
                      onTap:
                          () => Navigator.pushNamed(
                            context,
                            '/payment-verification-screen',
                          ),
                    ),
                    buildQuickActionTile(
                      color: Colors.purple,
                      icon: Icons.person_search,
                      subtitle: 'Access complete student information',
                      title: 'View Student Profiles',
                      onTap:
                          () => Navigator.pushNamed(
                            context,
                            '/user-management-screen',
                          ),
                    ),
                    buildQuickActionTile(
                      color: Colors.red,
                      icon: Icons.admin_panel_settings,
                      subtitle: 'Access complete admin information',
                      title: 'View Admin Profiles',
                      onTap:
                          () => Navigator.pushNamed(
                            context,
                            '/admin-management-screen',
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
