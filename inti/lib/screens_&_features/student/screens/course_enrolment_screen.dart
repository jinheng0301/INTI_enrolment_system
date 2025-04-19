import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/utils/color.dart';
import 'package:inti/common/utils/utils.dart';
import 'package:inti/common/widgets/drawer_list.dart';
import 'package:inti/common/widgets/error.dart';
import 'package:inti/common/widgets/loader.dart';
import 'package:inti/screens_&_features/student/controller/course_enrolment_controller.dart';
import 'package:inti/screens_&_features/student/widgets/course_container.dart';
import 'package:intl/intl.dart';

class CourseEnrolmentScreen extends ConsumerStatefulWidget {
  static const routeName = '/course-enrollment-screen';
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

  // Date check implementation
  // Check if the current date is within the enrollment period (1st to 8th of the month)
  bool get isEnrollmentOpen {
    final now = DateTime.now();
    return now.day >= 1 && now.day <= 8; // Enrollment open from 1st to 8th
  }

  // Get the enrollment period message
  // This method returns a message indicating the enrollment period and whether it's open or closed.
  String get enrollmentPeriodMesaage {
    final nextMonth = DateTime.now().month + 1;
    return isEnrollmentOpen
        ? 'Enrollment period: 1st - 8th of the month (OPEN NOW)'
        : 'Enrollment closed. Next period: 1st - 8th ${_monthName(nextMonth)}';
  }

  // Get the month name based on the month number
  String _monthName(int month) {
    return DateFormat('MMMM').format(DateTime(2025, month));
  }

  // This would be added to the CourseEnrolmentScreen class

  // Helper function to check if two time slots overlap
  bool _doTimeSlotsOverlap(
    Map<String, dynamic> slot1,
    Map<String, dynamic> slot2,
  ) {
    // First check if the days match
    if (slot1['day'] != slot2['day']) {
      return false; // Different days, no overlap
    }

    // Parse time strings to comparable format
    // We'll use a helper function to convert time strings like "2:00 PM" to minutes from midnight
    int slot1Start = _timeStringToMinutes(slot1['startTime']);
    int slot1End = _timeStringToMinutes(slot1['endTime']);
    int slot2Start = _timeStringToMinutes(slot2['startTime']);
    int slot2End = _timeStringToMinutes(slot2['endTime']);

    // Check if time periods overlap
    // Two time periods overlap if one starts before the other ends
    return (slot1Start < slot2End && slot1End > slot2Start);
  }

  // Helper function to convert time strings to minutes from midnight
  int _timeStringToMinutes(String timeStr) {
    // First check format - could be "2:00 PM" or "14:00" depending on your app's format
    // This example assumes a format like "2:00 PM" or "2:00 AM"

    // Extract hours, minutes, and AM/PM
    bool isPM = timeStr.toLowerCase().contains('pm');
    String timeDigits = timeStr.replaceAll(RegExp(r'[^\d:]'), '');
    List<String> parts = timeDigits.split(':');

    int hours = int.parse(parts[0]);
    int minutes = parts.length > 1 ? int.parse(parts[1]) : 0;

    // Convert to 24-hour format
    if (isPM && hours < 12) hours += 12;
    if (!isPM && hours == 12) hours = 0;

    return hours * 60 + minutes;
  }

  // Function to check if a course's schedule clashes with enrolled courses
  Future<Map<String, dynamic>?> _checkScheduleClash(
    Map<String, dynamic> newCourse,
  ) async {
    // Get all enrolled courses for the student
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseAuth)
              .collection('student_course_enrolment')
              .get();

      List<Map<String, dynamic>> enrolledCourses = [];
      for (var doc in snapshot.docs) {
        enrolledCourses.add(doc.data());
      }

      // Check for schedule clashes
      // First we need to parse the schedule for both new course and enrolled courses
      List<Map<String, dynamic>> newCourseSlots = [];

      // Parse new course schedule
      // Check if schedule is already a List or needs to be parsed
      if (newCourse['schedule'] is List) {
        newCourseSlots = List<Map<String, dynamic>>.from(newCourse['schedule']);
      } else {
        // Parse from string format if needed
        // This depends on your actual format, adjust as needed
        // For example purposes, let's assume schedule string is in format like:
        // "[{day: Monday, startTime: 9:00 AM, endTime: 11:00 AM}]"
        try {
          // Simple parsing for demo - you'll need more robust parsing based on your actual format
          String scheduleStr = newCourse['schedule'].toString();
          if (scheduleStr.contains('day:') &&
              scheduleStr.contains('startTime:')) {
            // Extract meaningful parts - this is a simplified example
            // You would need proper parsing based on your schedule string format
            RegExp dayRegex = RegExp(r'day: ([a-zA-Z]+)');
            RegExp startTimeRegex = RegExp(r'startTime: ([0-9:APM ]+)');
            RegExp endTimeRegex = RegExp(r'endTime: ([0-9:APM ]+)');

            var dayMatch = dayRegex.firstMatch(scheduleStr);
            var startMatch = startTimeRegex.firstMatch(scheduleStr);
            var endMatch = endTimeRegex.firstMatch(scheduleStr);

            if (dayMatch != null && startMatch != null && endMatch != null) {
              newCourseSlots.add({
                'day': dayMatch.group(1),
                'startTime': startMatch.group(1),
                'endTime': endMatch.group(1),
              });
            }
          }
        } catch (e) {
          print("Error parsing schedule: $e");
        }
      }

      // Check each enrolled course for schedule clashes
      for (var enrolledCourse in enrolledCourses) {
        String enrolledCourseId = enrolledCourse['courseId'];

        // Get the schedule for enrolled course
        List<Map<String, dynamic>> enrolledCourseSlots = [];

        // Get the schedule from Firestore for this enrolled course
        var courseDoc =
            await FirebaseFirestore.instance
                .collection('admin_add_courses')
                .where('courseCode', isEqualTo: enrolledCourseId)
                .get();

        if (courseDoc.docs.isNotEmpty) {
          var courseData = courseDoc.docs.first.data();

          // Parse enrolled course schedule similar to new course
          if (courseData['schedule'] is List) {
            enrolledCourseSlots = List<Map<String, dynamic>>.from(
              courseData['schedule'],
            );
          } else {
            // Similar parsing logic as above for string schedules
            try {
              String scheduleStr = courseData['schedule'].toString();
              if (scheduleStr.contains('day:') &&
                  scheduleStr.contains('startTime:')) {
                RegExp dayRegex = RegExp(r'day: ([a-zA-Z]+)');
                RegExp startTimeRegex = RegExp(r'startTime: ([0-9:APM ]+)');
                RegExp endTimeRegex = RegExp(r'endTime: ([0-9:APM ]+)');

                var dayMatch = dayRegex.firstMatch(scheduleStr);
                var startMatch = startTimeRegex.firstMatch(scheduleStr);
                var endMatch = endTimeRegex.firstMatch(scheduleStr);

                if (dayMatch != null &&
                    startMatch != null &&
                    endMatch != null) {
                  enrolledCourseSlots.add({
                    'day': dayMatch.group(1),
                    'startTime': startMatch.group(1),
                    'endTime': endMatch.group(1),
                  });
                }
              }
            } catch (e) {
              print("Error parsing schedule: $e");
            }
          }

          // Now check for clashes between new course slots and enrolled course slots
          for (var newSlot in newCourseSlots) {
            for (var enrolledSlot in enrolledCourseSlots) {
              if (_doTimeSlotsOverlap(newSlot, enrolledSlot)) {
                // Found a clash
                return {
                  'clashWith': enrolledCourse,
                  'courseData': courseData,
                  'clashSlot': enrolledSlot,
                  'newSlot': newSlot,
                };
              }
            }
          }
        }
      }

      // No clashes found
      return null;
    } catch (e) {
      print("Error checking schedule clash: $e");
      return null;
    }
  }

  // Function to show clash dialog
  void _showClashDialog(
    Map<String, dynamic> clashInfo,
    Map<String, dynamic> newCourse,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Schedule Clash Detected'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'The course you are trying to enroll in clashes with another course:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'New Course: ${newCourse['courseName']} (${newCourse['courseCode']})',
                ),
                Text(
                  'Clash With: ${clashInfo['courseData']['courseName']} (${clashInfo['courseData']['courseCode']})',
                ),
                SizedBox(height: 10),
                Text('Clash Details:'),
                Text('Day: ${clashInfo['clashSlot']['day']}'),
                Text(
                  'New Course Time: ${clashInfo['newSlot']['startTime']} - ${clashInfo['newSlot']['endTime']}',
                ),
                Text(
                  'Enrolled Course Time: ${clashInfo['clashSlot']['startTime']} - ${clashInfo['clashSlot']['endTime']}',
                ),
                SizedBox(height: 10),
                Text(
                  'You cannot enroll in both courses due to the schedule conflict. Please choose one of them.',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Keep Current Enrollment'),
            ),
            TextButton(
              onPressed: () {
                // Option to drop currently enrolled course and enroll in new one
                // This would require additional implementation
                Navigator.of(context).pop();
                _showConfirmSwapDialog(clashInfo, newCourse);
              },
              child: Text('Drop Enrolled & Take New Course'),
            ),
          ],
        );
      },
    );
  }

  // Function to confirm swapping courses
  void _showConfirmSwapDialog(
    Map<String, dynamic> clashInfo,
    Map<String, dynamic> newCourse,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Course Swap'),
          content: Text(
            'Are you sure you want to drop ${clashInfo['courseData']['courseName']} and enroll in ${newCourse['courseName']}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Implement the course swap logic
                try {
                  // First drop the clashing course
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(firebaseAuth)
                      .collection('student_course_enrolment')
                      .where(
                        'courseId',
                        isEqualTo: clashInfo['clashWith']['courseId'],
                      )
                      .get()
                      .then((snapshot) {
                        for (var doc in snapshot.docs) {
                          doc.reference.delete();
                        }
                      });

                  // Then enroll in the new course
                  final courseController = ref.read(
                    courseEnrolmentControllerProvider,
                  );

                  await courseController.enrollInCourse(
                    userId: widget.uid,
                    courseId: newCourse['courseCode'],
                    courseName: newCourse['courseName'] ?? 'N/A',
                    lecturerName: newCourse['lecturerName'] ?? 'N/A',
                    schedule: newCourse['schedule'] ?? 'N/A',
                    venue: newCourse['venue'] ?? 'N/A',
                    creditHours: newCourse['creditHours'] ?? 0,
                    context: context,
                    enrollmentDate: DateTime.now(),
                  );

                  Navigator.of(context).pop();

                  // Refresh enrolled courses list
                  await fetchEnrolledCourses();
                  setState(() {});

                  showSnackBar(context, 'Successfully swapped courses!');
                } catch (e) {
                  print("Error during course swap: $e");
                  showSnackBar(context, 'Failed to swap courses: $e');
                }
              },
              child: Text('Confirm Swap'),
            ),
          ],
        );
      },
    );
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
              'Course Enrollment',
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
                      enrollmentPeriodMesaage,
                      style: TextStyle(
                        fontSize: 14,
                        color: isEnrollmentOpen ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 5),

            // AVAILABLE COURSES
            enrollmentPeriodMesaage ==
                    'Enrollment closed. Next period: 1st - 8th ${_monthName(DateTime.now().month + 1)}'
                ? Center(
                  child: Text(
                    'Enrollment closed. Please come again on the 1st - 8th of each month.',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                )
                : Padding(
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
                                return Center(
                                  child: Text('No courses available'),
                                );
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
                                      lecturerName:
                                          course['lecturerName'] ?? 'N/A',
                                      schedule: course['schedule'].toString(),
                                      venue: course['venue'] ?? 'N/A',
                                      availableSeats:
                                          course['availableSeats']
                                              ?.toString() ??
                                          'N/A',
                                      creditHours: course['creditHours'] ?? 0,
                                      onEnroll: () async {
                                        if (!isEnrollmentOpen) {
                                          showSnackBar(
                                            context,
                                            '❌ Enrollment closed and only allowed from 1st to 8th of the month.',
                                          );
                                          return;
                                        }

                                        if (enrolledCourseIds.length >= 5) {
                                          showSnackBar(
                                            context,
                                            '❌ You can only enroll in 5 courses.',
                                          );
                                          return;
                                        }

                                        try {
                                          // Check for schedule clashes before enrolling
                                          final clashInfo =
                                              await _checkScheduleClash(course);

                                          if (clashInfo != null) {
                                            // Show clash dialog and return early
                                            _showClashDialog(clashInfo, course);
                                            return;
                                          }

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
                                            schedule:
                                                course['schedule'] ?? 'N/A',
                                            venue: course['venue'] ?? 'N/A',
                                            creditHours:
                                                course['creditHours'] ?? 0,
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
                                          print('Failed to enroll: $e');
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
