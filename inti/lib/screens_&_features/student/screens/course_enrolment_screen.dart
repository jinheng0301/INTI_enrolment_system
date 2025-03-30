import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/utils/color.dart';
import 'package:inti/common/widgets/drawer_list.dart';
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
                      'Enrolment period: 1st - 15th of the month',
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
                      child: ListView.builder(
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.white, // Background color
                              borderRadius: BorderRadius.circular(
                                10,
                              ), // Rounded corners
                              border: Border.all(
                                color: Colors.grey.shade300, // Border color
                                width: 1.5, // Border width
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(
                                    0.3,
                                  ), // Shadow color
                                  blurRadius: 5, // Blur radius
                                  offset: Offset(2, 2), // Shadow offset
                                ),
                              ],
                            ),
                            child: CourseContainer(
                              courseName: 'Introduction to Programming',
                              courseCode: 'CS101',
                              lecturerName: 'Dr. Jane Smith',
                              schedule: 'Mon, Wed',
                              venue: 'B2-01',
                              availableSeats: '25/30',
                              creditHours: 4,
                              onEnroll: () {
                                // Handle enrollment action here
                              },
                            ),
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
