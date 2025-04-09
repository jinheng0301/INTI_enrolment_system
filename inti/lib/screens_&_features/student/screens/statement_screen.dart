import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/utils/color.dart';
import 'package:inti/common/utils/utils.dart';
import 'package:inti/common/widgets/drawer_list.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class StatementScreen extends ConsumerStatefulWidget {
  static const String routeName = '/statement-screen';
  final String uid;

  StatementScreen({required this.uid});

  @override
  ConsumerState<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends ConsumerState<StatementScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  var firebaseAuth = FirebaseAuth.instance.currentUser?.uid;
  var userData = {};
  bool isLoading = false;
  List<Map<String, dynamic>> enrolledCourses = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getData();
    fetchEnrolledCourses();
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

  Future<void> fetchEnrolledCourses() async {
    try {
      var courseSnap =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.uid)
              .collection('student_course_enrolment')
              .get();

      setState(() {
        enrolledCourses = courseSnap.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  /// Generates a common timetable as a PDF file.
  /// In this sample, the timetable is hard-coded.
  /// You can adjust the timetable rows/columns as needed.
  Future<Uint8List> generateTimetablePdf(
    List<Map<String, dynamic>> courses,
  ) async {
    final pdf = pw.Document();

    // You can design your timetable layout here.
    // For example, assume the common timetable has 5 rows (one per course)
    // and each row displays Course Code, Course Name, Schedule, Venue.
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Common Timetable',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Course Code', 'Course Name', 'Schedule',  'Lecturer Name', 'Venue'],
                data:
                    courses.map((course) {
                      return [
                        course['courseId'] ?? '-',
                        course['courseName'] ?? '-',
                        course['schedule'] ?? '-',
                        course['lecturerName'] ?? '-',
                        course['venue'] ?? '-',
                      ];
                    }).toList(),
                cellAlignment: pw.Alignment.centerLeft,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
                cellStyle: pw.TextStyle(fontSize: 10),
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                },
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  void _downloadTimeTable() async {
    // Ensure user has exactly five enrolled courses
    if (enrolledCourses.length < 5) {
      showSnackBar(
        context,
        'You must enroll in 5 courses to view the timetable.',
      );
      return;
    }

    try {
      // Generate the timetable PDF using our helper.
      // (Here, enrolledCourses is used but if the timetable is common, you can also provide a fixed list.)
      final pdfData = await generateTimetablePdf(enrolledCourses);

      // Use the printing package to preview or share the PDF.
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfData,
      );
    } catch (e) {
      showSnackBar(context, 'Error getting timetable: $e');
    }
  }

  Widget buildTimetableTable() {
    if (enrolledCourses.isEmpty) {
      return Text(
        'No enrolled courses to display.',
        style: TextStyle(fontSize: 16),
      );
    }

    return DataTable(
      columnSpacing: 30,
      columns: const [
        DataColumn(label: Text('Course Code')),
        DataColumn(label: Text('Course Name')),
        DataColumn(label: Text('Schedule')),
        DataColumn(label: Text('Lecturer Name')),
        DataColumn(label: Text('Venue')),
      ],
      rows:
          enrolledCourses.map((course) {
            return DataRow(
              cells: [
                DataCell(Text(course['courseId'] ?? '-')),
                DataCell(Text(course['courseName'] ?? '-')),
                DataCell(Text(course['schedule'] ?? '-')),
                DataCell(Text(course['lecturerName'] ?? '-')),
                DataCell(Text(course['venue'] ?? '-')),
              ],
            );
          }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final height = MediaQuery.of(context).size.height;

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

      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Text(
              userData['username'] != null && userData.isNotEmpty
                  ? 'Welcome ${userData['username']} to Statement of Account'
                  : 'No data shown',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.picture_as_pdf, color: Colors.blue),
                  onPressed: _downloadTimeTable,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                  ),
                  label: Text(
                    'Download as PDF',
                    style: TextStyle(color: Colors.black),
                  ),
                ),

                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: Text(
                    'View payment history',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            /// Timetable View
            Align(
              alignment: Alignment.center,
              child: Text(
                'Your Timetable',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(height: 10),
            buildTimetableTable(),
          ],
        ),
      ),
    );
  }
}
