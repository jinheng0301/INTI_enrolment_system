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

  /// Generates a full timetable as a PDF file using the same logic as the on-screen timetable.
  Future<Uint8List> generateTimetablePdf(
    List<Map<String, dynamic>> courses,
  ) async {
    final pdf = pw.Document();
    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI'];
    final times = [
      '0800',
      '0900',
      '1000',
      '1100',
      '1200',
      '1300',
      '1400',
      '1500',
      '1600',
      '1700',
      '1800',
    ];

    // Build a map of timetable data.
    // Key: hour slot (e.g., '0800'); Value: Map from day to course details.
    Map<String, Map<String, String>> timetableData = {
      for (var time in times) time: {for (var day in days) day: ''},
    };

    // Fill in timetableData:
    // For each enrolled course, fill the corresponding time slots if the course spans multiple hours.
    for (var course in enrolledCourses) {
      String day = course['day'] ?? '';

      // Original times (may be "800", "900", "130", etc.)
      String rawStart = course['startTime'] ?? '';
      String rawEnd = course['endTime'] ?? '';

      // Ensure they are at least 4 digits
      String safeStart = rawStart.padLeft(4, '0');
      String safeEnd = rawEnd.padLeft(4, '0');

      // e.g. "800" -> "0800"

      int startHour = int.tryParse(safeStart.substring(0, 2)) ?? 0;
      int endHour = int.tryParse(safeEnd.substring(0, 2)) ?? 0;

      String courseInfo =
          '${course['courseId'] ?? ''} ${course['courseName'] ?? ''}\n'
          '[${course['venue'] ?? ''}] ${course['lecturerName'] ?? ''}';

      for (int hour = startHour; hour < endHour; hour++) {
        String key = (hour < 10 ? '0$hour' : '$hour') + '00';
        if (timetableData.containsKey(key) &&
            timetableData[key]!.containsKey(day)) {
          timetableData[key]![day] = courseInfo;
        }
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a3.landscape,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Student Timetable',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                columnWidths: {
                  0: pw.FlexColumnWidth(1.5), // Time slot column
                  for (int i = 1; i <= days.length; i++)
                    i: pw.FlexColumnWidth(3),
                },
                children: [
                  // Header Row
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'TIME',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      ...days.map(
                        (d) => pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            d,
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Data Rows for each time slot
                  ...times.map((time) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(time),
                        ),
                        ...days.map((day) {
                          return pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              timetableData[time]![day] ?? '',
                              textAlign: pw.TextAlign.center,
                            ),
                          );
                        }),
                      ],
                    );
                  }),
                ],
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

  /// Builds the complete timetable grid using Flutter's Table widget.
  Widget buildTimetableGrid() {
    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI'];
    final times = [
      '0800',
      '0900',
      '1000',
      '1100',
      '1200',
      '1300',
      '1400',
      '1500',
      '1600',
      '1700',
      '1800',
    ];

    // Build a map for the grid.
    Map<String, Map<String, String>> timetableData = {
      for (var time in times) time: {for (var day in days) day: ''},
    };

    // Debug: Print enrolledCourses to ensure data is being fetched
    print('Enrolled Courses: $enrolledCourses');

    for (var course in enrolledCourses) {
      String day = course['day'] ?? '';
      String startTime = course['startTime'] ?? '';
      String endTime = course['endTime'] ?? '';
      String courseInfo =
          '${course['courseCode'] ?? ''}\n${course['courseName'] ?? ''}\n[${course['venue'] ?? ''}]';

      // Debug: Print course details
      print('Processing course: $course');

      // Validate startTime and endTime lengths
      if (startTime.length < 4 || endTime.length < 4) {
        print('Invalid time format for course: $course');
        continue; // Skip this course if times are invalid
      }

      int startHour = int.tryParse(startTime.substring(0, 2)) ?? 0;
      int endHour = int.tryParse(endTime.substring(0, 2)) ?? 0;

      for (int hour = startHour; hour < endHour; hour++) {
        String key = (hour < 10 ? '0$hour' : '$hour') + '00';
        if (timetableData.containsKey(key) &&
            timetableData[key]!.containsKey(day)) {
          timetableData[key]![day] = courseInfo;
        }
      }
    }

    // Debug: Print timetableData to verify grid population
    print('Timetable Data: $timetableData');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Table(
          border: TableBorder.all(width: 0.5, color: Colors.grey),
          defaultColumnWidth: FixedColumnWidth(120),
          children: [
            // Header Row
            TableRow(
              decoration: BoxDecoration(color: Colors.grey[300]),
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'TIME',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...days.map(
                  (day) => Container(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      day,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            // Data Rows
            ...times.map((time) {
              return TableRow(
                children: [
                  Container(padding: EdgeInsets.all(8), child: Text(time)),
                  ...days.map((day) {
                    return Container(
                      padding: EdgeInsets.all(6),
                      height: 50,
                      child: Text(
                        timetableData[time]![day] ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showTransactionHistoryDialog() async {
    setState(() {
      isLoading = true;
    });

    List<Map<String, dynamic>> paymentHistory = [];
    String errorMessage = '';

    try {
      // Get current user's email from userData
      final userEmail = userData['email'] as String?;

      if (userEmail == null) {
        errorMessage = 'User email not found';
      } else {
        // First, get the payment record to find the paymentId
        final paymentRecordSnapshot =
            await FirebaseFirestore.instance
                .collection('user_payment_record')
                .where('primaryEmail', isEqualTo: userEmail)
                .limit(1)
                .get();

        if (paymentRecordSnapshot.docs.isEmpty) {
          errorMessage = 'No payment record found';
        } else {
          // Get the payment ID
          final paymentId = paymentRecordSnapshot.docs.first.id;

          // Get payment transactions for this payment record
          final transactionsSnapshot =
              await FirebaseFirestore.instance
                  .collection('payment_transactions')
                  .where('paymentId', isEqualTo: paymentId)
                  .orderBy('timestamp', descending: true)
                  .get();

          paymentHistory =
              transactionsSnapshot.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList();
        }
      }
    } catch (e) {
      print(errorMessage);
      errorMessage = 'Error fetching payment history: $e';
    } finally {
      setState(() {
        isLoading = false;
      });
    }

    // Show the dialog with fetched data
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.history, color: Colors.blue),
                SizedBox(width: 10),
                Text('Transaction History'),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(maxHeight: 400),
              child:
                  errorMessage.isNotEmpty
                      ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            SizedBox(height: 16),
                            Text(
                              errorMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ],
                        ),
                      )
                      : paymentHistory.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue,
                              size: 48,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No payment transactions found',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                      : Column(
                        children: [
                          // Header row
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade400,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Date',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Type',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Amount',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Balance',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // List of transactions
                          Expanded(
                            child: ListView.builder(
                              itemCount: paymentHistory.length,
                              itemBuilder: (context, index) {
                                final item = paymentHistory[index];
                                final timestamp =
                                    item['timestamp'] as Timestamp?;
                                final date =
                                    timestamp != null
                                        ? DateTime.fromMillisecondsSinceEpoch(
                                          timestamp.millisecondsSinceEpoch,
                                        )
                                        : DateTime.now();
                                final formattedDate =
                                    '${date.day}/${date.month}/${date.year}';
                                final type =
                                    item['type'] as String? ?? 'Unknown';
                                final amount = item['amount'] as num? ?? 0;
                                final balance =
                                    item['balanceAfter'] as num? ?? 0;

                                // Determine if this is a payment or reload
                                final isPayment =
                                    type.toLowerCase() == 'payment';

                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(formattedDate),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          children: [
                                            Icon(
                                              isPayment
                                                  ? Icons.payments_outlined
                                                  : Icons
                                                      .account_balance_wallet,
                                              color:
                                                  isPayment
                                                      ? Colors.red
                                                      : Colors.green,
                                              size: 16,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              type,
                                              style: TextStyle(
                                                color:
                                                    isPayment
                                                        ? Colors.red.shade700
                                                        : Colors.green.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          isPayment
                                              ? '-\$${amount.toStringAsFixed(2)}'
                                              : '+\$${amount.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color:
                                                isPayment
                                                    ? Colors.red.shade700
                                                    : Colors.green.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          '\$${balance.toStringAsFixed(2)}',
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    }
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
                  onPressed: _showTransactionHistoryDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: Text(
                    'View Transaction History',
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
            Expanded(child: buildTimetableGrid()),
          ],
        ),
      ),
    );
  }
}
