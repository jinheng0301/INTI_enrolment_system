import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/utils/color.dart';
import 'package:inti/common/utils/utils.dart';
import 'package:inti/common/widgets/drawer_list.dart';
import 'package:inti/screens_&_features/student/controller/course_enrolment_controller.dart';
import 'package:inti/screens_&_features/student/repository/course_enrolment_repository.dart';

class AddDropScreen extends ConsumerStatefulWidget {
  static const routeName = '/add-drop-screen';
  final String uid;

  AddDropScreen({required this.uid});

  @override
  ConsumerState<AddDropScreen> createState() => _AddDropScreenState();
}

class _AddDropScreenState extends ConsumerState<AddDropScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController dropReasonController = TextEditingController();
  var firebaseAuth = FirebaseAuth.instance.currentUser?.uid;
  final _formKey = GlobalKey<FormState>();
  var userData = {};
  bool isLoading = false;
  List<String> enrolledCourseIds = [];
  List<Map<String, dynamic>> enrolledCourses = [];
  List<String> enrolledDropRequests = []; // List to track pending drop requests
  List<String> approvedDropCourseIds = [];
  // Track courses that were approved for dropping

  @override
  void initState() {
    super.initState();
    getData();
    getEnrolledCourses();
    getPendingDropRequests();
    getApprovedDropRequests();
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

  void getEnrolledCourses() async {
    try {
      // Fetch the enrolled courses from the user's subcollection
      var coursesSnap =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.uid)
              .collection('student_course_enrolment')
              .get();

      // Debug: Print fetched data
      print("Fetched courses: ${coursesSnap.docs.map((doc) => doc.data())}");

      setState(() {
        enrolledCourses = coursesSnap.docs.map((doc) => doc.data()).toList();
        enrolledCourseIds =
            coursesSnap.docs
                .map((doc) => doc['courseId']?.toString() ?? '')
                .toList();
      });
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  // New method: Fetch pending drop requests from Firestore
  void getPendingDropRequests() async {
    try {
      QuerySnapshot query =
          await FirebaseFirestore.instance
              .collection('drop_requests')
              .where('studentId', isEqualTo: widget.uid)
              .where('status', isEqualTo: 'pending')
              .get();

      setState(() {
        enrolledDropRequests =
            query.docs.map((doc) => doc['courseId'] as String).toList();
      });
    } catch (e) {
      print("❌ Error fetching pending drop requests: $e");
    }
  }

  Future<void> _submitDropRequest(String courseId, String courseName) async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() => isLoading = true);

        // Call the controller to submit drop request
        await ref
            .read(courseEnrolmentControllerProvider)
            .submitDropRequest(
              studentId: widget.uid,
              studentName: userData['username'] ?? 'Unknown',
              courseId: courseId,
              courseName: courseName,
              dropReason: dropReasonController.text,
              context: context,
            );

        // Update local state: add courseId to pending drop requests list
        setState(() {
          enrolledDropRequests.add(courseId);
        });

        Navigator.of(context).pop(); // Close dialog

        dropReasonController.clear();

        showSnackBar(context, 'Drop request submitted for admin approval');
      } catch (e) {
        showSnackBar(context, 'Failed to submit drop request: $e');
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _showDropReasonDialog(String courseId, String courseName) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Give your reason for dropping $courseName'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Give a suitable reason for your drop course'),
                SizedBox(height: 10),
                TextFormField(
                  controller: dropReasonController,
                  decoration: InputDecoration(
                    labelText: 'Enter your reason for dropping...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 1,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the drop reason';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _submitDropRequest(courseId, courseName),
              child: Text('Drop!'),
            ),
          ],
        );
      },
    );
  }

  bool get canAddCourse {
    final now = DateTime.now();
    // Can add course if: User has an approved drop AND total courses < 5 AND current date > 8th of the month
    return approvedDropCourseIds.isNotEmpty &&
        enrolledCourses.length < 5 &&
        now.day >= 8;
  }

  // Add this method to fetch approved drop requests
  void getApprovedDropRequests() async {
    try {
      QuerySnapshot query =
          await FirebaseFirestore.instance
              .collection('drop_requests')
              .where('studentId', isEqualTo: widget.uid)
              .where('status', isEqualTo: 'approved')
              .where('used', isEqualTo: false) // Only get unused approved drops
              .get();

      setState(() {
        approvedDropCourseIds =
            query.docs.map((doc) => doc['courseId'] as String).toList();
      });

      print("✅ Approved drop requests fetched: $approvedDropCourseIds");
    } catch (e) {
      print("❌ Error fetching approved drop requests: $e");
    }
  }

  Future<void> _showAddCourseDialog() async {
    // Fetch available courses (excluding already enrolled courses)
    List<Map<String, dynamic>> availableCourses = [];

    try {
      QuerySnapshot coursesSnapshot =
          await FirebaseFirestore.instance
              .collection('admin_add_courses')
              .get();

      availableCourses =
          coursesSnapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .where(
                (course) => !enrolledCourseIds.contains(course['courseCode']),
              )
              .toList();
    } catch (e) {
      showSnackBar(context, "Error fetching available courses: $e");
      return;
    }

    if (availableCourses.isEmpty) {
      showSnackBar(context, "No available courses to add.");
      return;
    }

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.6,
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Available Courses',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 15),
                Text(
                  'You have dropped a course, so you can add a new one.',
                  style: TextStyle(fontSize: 14, color: Colors.green),
                ),

                SizedBox(height: 20),

                Expanded(
                  child: ListView.builder(
                    itemCount: availableCourses.length,
                    itemBuilder: (context, index) {
                      final course = availableCourses[index];

                      return Container(
                        margin: EdgeInsets.only(bottom: 15),
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
                        child: ListTile(
                          contentPadding: EdgeInsets.all(15),
                          title: Text(
                            course['courseCode'] ?? 'Unknown',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(course['courseName'] ?? 'Unknown Course'),

                              Text(
                                'Lecturer: ${course['lecturerName'] ?? 'TBA'}',
                              ),

                              Text(
                                'Credits: ${course['creditHours']?.toString() ?? '0'}',
                              ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _enrollInCourse(course),
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(
                                Colors.green,
                              ),
                            ),
                            child: Text(
                              'Add',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 10),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _enrollInCourse(Map<String, dynamic> course) async {
    try {
      setState(() => isLoading = true);

      // Check for schedule clashes before enrolling
      final clashInfo = await _checkScheduleClash(course);

      if (clashInfo != null) {
        // Show clash dialog and return early
        _showClashDialog(clashInfo, course);
        setState(() => isLoading = false);
        return;
      }

      await ref
          .read(courseEnrolmentControllerProvider)
          .enrollInCourse(
            userId: widget.uid,
            courseId: course['courseCode'],
            courseName: course['courseName'] ?? 'N/A',
            lecturerName: course['lecturerName'] ?? 'N/A',
            schedule: course['schedule'] ?? 'N/A',
            venue: course['venue'] ?? 'N/A',
            creditHours: course['creditHours'] ?? 0,
            context: context,
            enrollmentDate: DateTime.now(),
          );

      // Find the first approved drop request
      QuerySnapshot approvedDrops =
          await FirebaseFirestore.instance
              .collection('drop_requests')
              .where('studentId', isEqualTo: widget.uid)
              .where('status', isEqualTo: 'approved')
              .where('used', isEqualTo: false)
              .limit(1)
              .get();

      // Mark it as used
      if (approvedDrops.docs.isNotEmpty) {
        String dropRequestId = approvedDrops.docs.first.id;
        await ref
            .read(courseEnrolmentRepositoryProvider)
            .markDropRequestUsed(
              studentId: widget.uid,
              dropRequestId: dropRequestId,
            );
      }

      // Close the dialog
      Navigator.pop(context);

      // Refresh the course lists
      getEnrolledCourses();
      getApprovedDropRequests();

      showSnackBar(
        context,
        'Successfully enrolled in ${course['courseName']}!',
      );
    } catch (e) {
      showSnackBar(context, 'Failed to enroll: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }
  // First, add these helper functions from CourseEnrolmentScreen to AddDropScreen

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
    int slot1Start = _timeStringToMinutes(slot1['startTime']);
    int slot1End = _timeStringToMinutes(slot1['endTime']);
    int slot2Start = _timeStringToMinutes(slot2['startTime']);
    int slot2End = _timeStringToMinutes(slot2['endTime']);

    // Check if time periods overlap
    return (slot1Start < slot2End && slot1End > slot2Start);
  }

  // Helper function to convert time strings to minutes from midnight
  int _timeStringToMinutes(String timeStr) {
    // Check format - could be "2:00 PM" or "14:00"
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
              .doc(widget.uid)
              .collection('student_course_enrolment')
              .get();

      List<Map<String, dynamic>> enrolledCourses = [];
      for (var doc in snapshot.docs) {
        enrolledCourses.add(doc.data());
      }

      // Check for schedule clashes
      List<Map<String, dynamic>> newCourseSlots = [];

      // Parse new course schedule
      if (newCourse['schedule'] is List) {
        newCourseSlots = List<Map<String, dynamic>>.from(newCourse['schedule']);
      } else {
        // Parse from string format if needed
        try {
          String scheduleStr = newCourse['schedule'].toString();
          if (scheduleStr.contains('day:') &&
              scheduleStr.contains('startTime:')) {
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

        // Skip checking against courses that are being dropped
        if (enrolledDropRequests.contains(enrolledCourseId)) {
          continue;
        }

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
                  'The course you are trying to add clashes with another course:',
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
                  'You cannot enroll in both courses due to the schedule conflict.',
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
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Option to drop currently enrolled course and enroll in new one
                Navigator.of(context).pop();
                _showConfirmSwapDialog(clashInfo, newCourse);
              },
              child: Text('Swap Courses'),
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
                      .doc(widget.uid)
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
                  await _enrollInCourse(newCourse);

                  Navigator.of(context).pop();
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

      body: Column(
        children: [
          Text(
            'Add/Drop your subject',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 20),

          // ADD NEW COURSE BUTTON
          // Only show if user has an approved drop request and less than 5 courses
          ElevatedButton(
            onPressed: canAddCourse ? _showAddCourseDialog : null,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(
                canAddCourse ? Colors.yellow : Colors.grey,
              ),
            ),
            child: Text(
              'Add new course',
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),

          //SHOW ENROLLED COURSES OF CURRENT USER
          Expanded(
            child: Padding(
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
                  children: [
                    Text(
                      userData['username'] != null && userData.isNotEmpty
                          ? 'Show ${userData['username']} enrolled course'
                          : 'No username to show',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 10),

                    Expanded(
                      child:
                          enrolledCourses.isEmpty
                              ? Center(
                                child: Text(
                                  'No enrolled course found.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              )
                              : ListView.builder(
                                itemCount: enrolledCourses.length,
                                itemBuilder: (context, index) {
                                  final courses = enrolledCourses[index];

                                  return Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Container(
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
                                      child: ListTile(
                                        contentPadding:
                                            EdgeInsetsDirectional.all(20),
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.deepOrange,
                                          child: Text(
                                            courses['courseId']?[0] ?? '?',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          courses['courseId']?.toString() ??
                                              'Unknown Course',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(height: 8),
                                            Text(
                                              courses['courseName']
                                                      ?.toString() ??
                                                  'No Name',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.normal,
                                                color: Colors.black54,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              '${courses['creditHours']?.toString() ?? '0'} Credit Hours',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.normal,
                                                color: Colors.black45,
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: ElevatedButton(
                                          onPressed:
                                              enrolledDropRequests.contains(
                                                    courses['courseId'],
                                                  )
                                                  ? null // Disable if already submitted
                                                  : () => _showDropReasonDialog(
                                                    courses['courseId'],
                                                    courses['courseName'] ??
                                                        'Course',
                                                  ),
                                          style: ButtonStyle(
                                            backgroundColor:
                                                WidgetStateProperty.all(
                                                  enrolledDropRequests.contains(
                                                        courses['courseId'],
                                                      )
                                                      ? Colors
                                                          .grey // Disabled color
                                                      : Colors.red,
                                                ),
                                          ),
                                          child: Text(
                                            'Drop',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w300,
                                              color: Colors.black,
                                            ),
                                          ),
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
          ),
        ],
      ),
    );
  }
}
