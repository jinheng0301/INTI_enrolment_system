import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/provider/course_enrolment_provider.dart';
import 'package:inti/common/utils/color.dart';
import 'package:inti/common/utils/utils.dart';
import 'package:inti/common/widgets/drawer_list.dart';
import 'package:inti/common/widgets/error.dart';
import 'package:inti/common/widgets/loader.dart';
import 'package:inti/screens_&_features/student/widgets/course_container.dart';

class CourseEnrolmentScreen extends ConsumerStatefulWidget {
  static const routeName = '/course-enrolment-screen';
  final String uid;

  CourseEnrolmentScreen({required this.uid});

  @override
  ConsumerState<CourseEnrolmentScreen> createState() =>
      _CourseEnrolmentScreenState();
}

class _CourseEnrolmentScreenState extends ConsumerState<CourseEnrolmentScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  var firebaseAuth = FirebaseAuth.instance.currentUser?.uid;
  String monthlySemester = 'JAN2025';
  List<Map<String, dynamic>> availableCourses = [];
  List<String> enrolledCourseIds = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchEnrolledCourses();
  }

  Future<void> fetchEnrolledCourses() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseAuth)
              .collection('student_course_enrolment')
              .get();

      setState(() {
        enrolledCourseIds =
            snapshot.docs.map((doc) => doc['courseId'] as String).toList();
      });
    } catch (e) {
      print("❌ Error fetching enrolled courses: $e");
    }
  }

  Stream<List<Map<String, dynamic>>> fetchCourses() {
    return FirebaseFirestore.instance
        .collection('admin_add_courses')
        .snapshots()
        .map((snapshot) {
          final courses = snapshot.docs.map((doc) => doc.data()).toList();
          return courses
              .where(
                (course) => !enrolledCourseIds.contains(course['courseCode']),
              )
              .toList(); // Filter out already enrolled courses
        });
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
        title: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/student-home-screen');
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

      body: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              'Course Enrolment',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.all(25),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Semester',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            monthlySemester,
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 10),

                    Text(
                      'Enrolment period: 1st - 8th of the month',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // AVAILABLE COURSES
            Padding(
              padding: const EdgeInsets.all(25),
              child: Container(
                padding: EdgeInsets.all(16),
                height: height * .7,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Courses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 10),

                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: fetchCourses(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Loader();
                          } else if (snapshot.hasError) {
                            return ErrorScreen(
                              error: snapshot.error.toString(),
                            );
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return Center(child: Text('No courses available'));
                          }

                          final courses = snapshot.data!;

                          return ListView.builder(
                            itemCount: courses.length,
                            itemBuilder: (context, index) {
                              final course = courses[index];

                              return Container(
                                margin: EdgeInsets.only(bottom: 20),
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
                                child: CourseContainer(
                                  courseName: course['courseName'] ?? 'N/A',
                                  courseCode: course['courseCode'] ?? 'N/A',
                                  lecturerName: course['lecturerName'] ?? 'N/A',
                                  schedule: course['schedule'] ?? 'N/A',
                                  venue: course['venue'] ?? 'N/A',
                                  availableSeats:
                                      course['availableSeats']?.toString() ??
                                      'N/A',
                                  creditHours: course['creditHours'] ?? 0,
                                  onEnroll: () async {
                                    if (enrolledCourseIds.length >= 5) {
                                      showSnackBar(
                                        context,
                                        '❌ You can only enroll in 5 courses.',
                                      );
                                      return;
                                    }

                                    try {
                                      final courseController = ref.read(
                                        courseEnrolmentControllerProvider,
                                      );

                                      await courseController.enrollInCourse(
                                        userId: widget.uid,
                                        courseId: course['courseCode'],
                                        courseName:
                                            course['courseName'] ?? 'N/A',
                                        lecturerName:
                                            course['lecturerName'] ?? 'N/A',
                                        schedule: course['schedule'] ?? 'N/A',
                                        venue: course['venue'] ?? 'N/A',
                                        creditHours: course['creditHours'] ?? 0,
                                        context: context,
                                        enrollmentDate: DateTime.now(),
                                      );

                                      // ✅ Refresh the list by re-fetching enrolled courses
                                      await fetchEnrolledCourses();

                                      // ✅ Trigger UI update
                                      setState(() {});

                                      showSnackBar(
                                        context,
                                        'Enrolled successfully in ${course['courseCode']} and ${course['courseName']}!',
                                      );
                                    } catch (e) {
                                      showSnackBar(
                                        context,
                                        'Failed to enroll: $e',
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          );
                        },
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
