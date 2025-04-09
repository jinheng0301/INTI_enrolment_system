import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/utils/color.dart';
import 'package:inti/common/utils/utils.dart';
import 'package:inti/common/widgets/drawer_list.dart';
import 'package:inti/common/widgets/loader.dart';
import 'package:inti/screens_&_features/admin/controllers/manage_course_controller.dart';

class ManageCourseScreen extends ConsumerStatefulWidget {
  static const routeName = '/manage-course-screen';
  final String uid;

  ManageCourseScreen({required this.uid});

  @override
  ConsumerState<ManageCourseScreen> createState() => _ManageCourseScreenState();
}

class _ManageCourseScreenState extends ConsumerState<ManageCourseScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController courseNameController = TextEditingController();
  final TextEditingController courseCodeController = TextEditingController();
  final TextEditingController lecturerNameController = TextEditingController();
  final TextEditingController scheduleController = TextEditingController();
  final TextEditingController venueController = TextEditingController();
  final TextEditingController availableSeatsController =
      TextEditingController();
  final TextEditingController creditHoursController = TextEditingController();
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

  Future<void> _showAddCourseDialog() async {
    clearForm();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add new course'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: courseNameController,
                    decoration: InputDecoration(labelText: 'Course Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the course name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: courseCodeController,
                    decoration: InputDecoration(labelText: 'Course Code'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the course code';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: lecturerNameController,
                    decoration: InputDecoration(labelText: 'Lecturer Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the lecturer name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: scheduleController,
                    decoration: InputDecoration(labelText: 'Schedule'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the schedule';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: venueController,
                    decoration: InputDecoration(labelText: 'Venue'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the venue';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: availableSeatsController,
                    decoration: InputDecoration(labelText: 'Available Seats'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the available seats';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: creditHoursController,
                    decoration: InputDecoration(labelText: 'Credit Hours'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the credit hours';
                      }
                      return null;
                    },
                  ),
                ],
              ),
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
                if (_formKey.currentState!.validate()) {
                  ref
                      .read(manageCourseControllerProvider)
                      .addCourse(
                        courseName: courseNameController.text,
                        courseCode: courseCodeController.text,
                        lecturerName: lecturerNameController.text,
                        schedule: scheduleController.text,
                        venue: venueController.text,
                        availableSeats: int.parse(
                          availableSeatsController.text,
                        ),
                        creditHours: int.parse(creditHoursController.text),
                        context: context,
                      );
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add course!'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(Map<String, dynamic> course) {
    courseNameController.text = course['courseName'];
    courseCodeController.text = course['courseCode'];
    lecturerNameController.text = course['lecturerName'];
    scheduleController.text = course['schedule'];
    venueController.text = course['venue'];
    availableSeatsController.text = course['availableSeats'].toString();
    creditHoursController.text = course['creditHours'].toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Course'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: courseNameController,
                    decoration: InputDecoration(labelText: 'Course Name'),
                  ),
                  TextFormField(
                    controller: courseCodeController,
                    decoration: InputDecoration(labelText: 'Course Code'),
                  ),
                  TextFormField(
                    controller: lecturerNameController,
                    decoration: InputDecoration(labelText: 'Lecturer Name'),
                  ),
                  TextFormField(
                    controller: scheduleController,
                    decoration: InputDecoration(labelText: 'Schedule'),
                  ),
                  TextFormField(
                    controller: venueController,
                    decoration: InputDecoration(labelText: 'Venue'),
                  ),
                  TextFormField(
                    controller: availableSeatsController,
                    decoration: InputDecoration(labelText: 'Available Seats'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: creditHoursController,
                    decoration: InputDecoration(labelText: 'Credit Hours'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
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
                if (_formKey.currentState!.validate()) {
                  ref
                      .read(manageCourseControllerProvider)
                      .editCourse(
                        courseId: course['id'], // Pass the course ID
                        courseName: courseNameController.text,
                        courseCode: courseCodeController.text,
                        lecturerName: lecturerNameController.text,
                        schedule: scheduleController.text,
                        venue: venueController.text,
                        availableSeats: int.parse(
                          availableSeatsController.text,
                        ),
                        creditHours: int.parse(creditHoursController.text),
                        context: context,
                      );
                  Navigator.of(context).pop();
                }
              },
              child: Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(String courseId) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete this course?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Call the deleteCourse method from the controller
                await ref
                    .read(manageCourseControllerProvider)
                    .deleteCourse(courseId: courseId, context: context);
                Navigator.of(context).pop();
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void clearForm() {
    courseNameController.clear();
    courseCodeController.clear();
    lecturerNameController.clear();
    scheduleController.clear();
    venueController.clear();
    availableSeatsController.clear();
    creditHoursController.clear();
  }

  @override
  Widget build(BuildContext context) {
    // final height = MediaQuery.of(context).size.height;
    final coursesAsync = ref.watch(coursesStreamProvider);

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
            Navigator.pushNamed(context, '/admin-home-screen');
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
                    ? '${userData['username']} admin, this is for you to add the course. '
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

          ElevatedButton(
            onPressed: _showAddCourseDialog,
            child: Text(
              'Add new course',
              style: TextStyle(
                fontWeight: FontWeight.w300,
                fontSize: 15,
                color: textColor,
              ),
            ),
          ),

          SizedBox(height: 20),

          Expanded(
            child: coursesAsync.when(
              loading: () => Center(child: Loader()),
              error: (error, stack) {
                if (error.toString().contains('permission-denied')) {
                  return Center(
                    child: Text(
                      'You do not have permission to view the courses.',
                    ),
                  );
                }
                return Center(child: Text('Error: $error'));
              },
              data: (courses) {
                if (courses.isEmpty) {
                  return Center(child: Text('No courses found.'));
                }

                // Use a DataTable to replicate your sample UI
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 5,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Course ID')),
                          DataColumn(label: Text('Course Name')),
                          DataColumn(label: Text('Credits')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows:
                            courses.map((course) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(course.courseCode)),
                                  DataCell(Text(course.courseName)),
                                  DataCell(Text(course.creditHours.toString())),
                                  DataCell(
                                    Row(
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            // TODO: Implement edit logic
                                            _showEditDialog({
                                              'id': course.id,
                                              'courseName': course.courseName,
                                              'courseCode': course.courseCode,
                                              'lecturerName':
                                                  course.lecturerName,
                                              'schedule': course.schedule,
                                              'venue': course.venue,
                                              'availableSeats':
                                                  course.availableSeats,
                                              'creditHours': course.creditHours,
                                            });
                                          },
                                          child: Text('Edit'),
                                        ),
                                        SizedBox(width: 8),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          onPressed: () {
                                            // TODO: Implement delete logic
                                            _showDeleteConfirmationDialog(
                                              course.id,
                                            );
                                          },
                                          child: Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
