import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/utils/color.dart';
import 'package:inti/common/utils/utils.dart';
import 'package:inti/common/widgets/drawer_list.dart';
import 'package:inti/common/widgets/loader.dart';
import 'package:inti/screens_&_features/student/widgets/announcements_section.dart';
import 'package:inti/screens_&_features/student/widgets/build_banner_section.dart';
import 'package:inti/screens_&_features/student/widgets/enrolled_courses_section.dart';
import 'package:inti/screens_&_features/student/widgets/payment_summary_section.dart';
// Add this for date formatting

class StudentHomeScreen extends ConsumerStatefulWidget {
  static const routeName = '/student-home-screen';
  final String uid;

  const StudentHomeScreen({Key? key, required this.uid}) : super(key: key);

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  Map<String, dynamic> _userData = {};
  bool _isLoading = false;
  List<Map<String, dynamic>> _enrolledCourses = [];
  List<Map<String, dynamic>> _announcements = [];

  // Payment due date (example)
  final DateTime _paymentDueDate = DateTime.now().add(const Duration(days: 14));

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _getUserData(),
        _getEnrolledCourses(),
        _getAnnouncements(),
      ]);
    } catch (e) {
      showSnackBar(context, 'Error loading data: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getUserData() async {
    try {
      final userSnap =
          await _firestore.collection('users').doc(widget.uid).get();

      if (userSnap.exists && userSnap.data() != null) {
        setState(() {
          _userData = userSnap.data()!;
        });
      }

      print('User data fetched: $_userData');
    } catch (e) {
      showSnackBar(context, 'Error fetching user data: ${e.toString()}');
    }
  }

  Future<void> _getEnrolledCourses() async {
    try {
      final coursesSnap =
          await _firestore
              .collection('users')
              .doc(widget.uid)
              .collection('student_course_enrolment')
              .get();

      setState(() {
        _enrolledCourses = coursesSnap.docs.map((doc) => doc.data()).toList();
      });

      print('Enrolled courses: $_enrolledCourses');
    } catch (e) {
      showSnackBar(context, 'Error fetching courses: ${e.toString()}');
    }
  }

  Future<void> _getAnnouncements() async {
    // Simulate fetching announcements (replace with actual implementation)
    setState(() {
      _announcements = [
        {
          'title': 'New course registration opens Monday!',
          'description':
              'Please register for your courses before the deadline.',
          'date': DateTime.now().subtract(const Duration(hours: 5)),
        },
        {
          'title': 'Campus event: Career Fair',
          'description': 'Join our annual career fair with 30+ companies.',
          'date': DateTime.now().subtract(const Duration(days: 2)),
        },
        {
          'title': 'Library hours extended',
          'description': 'The main library will now be open until midnight.',
          'date': DateTime.now().subtract(const Duration(days: 3)),
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;

    return Scaffold(
      key: _scaffoldKey,

      drawer: DrawerList(uid: _currentUserId ?? ''),

      appBar: AppBar(
        backgroundColor: tabColor,
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Image.asset('images/inti_logo.png', height: 40),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications, color: Colors.yellow),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.person, color: Colors.yellow),
          ),
        ],
        elevation: 4.0, // Add shadow
      ),

      body:
          _isLoading
              ? const Center(child: Loader())
              : RefreshIndicator(
                onRefresh: _loadAllData,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // BANNER AND TITLE
                      BuildBannerSection(
                        height: height * .7,
                        title:
                            _userData.isNotEmpty &&
                                    _userData['username'] != null
                                ? 'Welcome back, ${_userData['username']}'
                                : 'Welcome, Student',
                        subtitle: _userData['programme'] ?? 'Not Specified',
                      ),

                      SizedBox(height: 30),

                      // PAYMENT SUMMARY
                      PaymentSummarySection(
                        userId: _currentUserId ?? '',
                        userData: _userData,
                        paymentDueDate: _paymentDueDate,
                      ),

                      SizedBox(height: 30),

                      // ENROLLED COURSES
                      EnrolledCoursesSection(enrolledCourses: _enrolledCourses),

                      SizedBox(height: 30),

                      // ANNOUNCEMENTS
                      AnnouncementsSection(announcements: _announcements),

                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
    );
  }
}
