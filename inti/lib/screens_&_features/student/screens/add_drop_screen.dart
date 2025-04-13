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
          title: Text('Drop $courseName reason dialog'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Give a suitable reason for your drop course'),
                TextFormField(
                  controller: dropReasonController,
                  decoration: InputDecoration(
                    labelText: 'Enter your reason for dropping...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
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
