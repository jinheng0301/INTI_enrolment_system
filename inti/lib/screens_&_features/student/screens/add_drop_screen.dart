import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/provider/course_enrolment_provider.dart';
import 'package:inti/common/utils/color.dart';
import 'package:inti/common/utils/utils.dart';
import 'package:inti/common/widgets/drawer_list.dart';

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

  @override
  void initState() {
    super.initState();
    getData();
    getEnrolledCourses();
    getPendingDropRequests();
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

          //SHOW ENROLLED COURSES OF CURRENT USER
          Container(
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                                    contentPadding: EdgeInsetsDirectional.all(
                                      20,
                                    ),
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
                                          courses['courseName']?.toString() ??
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
        ],
      ),
    );
  }
}
