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
    setState(() {
      isLoading = true;
    });

    try {
      var courseSnap =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.uid)
              .collection('student_course_enrolment')
              .get();

      setState(() {
        enrolledCourses = courseSnap.docs.map((doc) => doc.data()).toList();
        isLoading = false;
      });

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
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    final shortDays = ['MON', 'TUE', 'WED', 'THU', 'FRI'];
    final timeSlots = [
      '08:00-09:00',
      '09:00-10:00',
      '10:00-11:00',
      '11:00-12:00',
      '12:00-13:00',
      '13:00-14:00',
      '14:00-15:00',
      '15:00-16:00',
      '16:00-17:00',
      '17:00-18:00',
    ];

    // Create structure to hold timetable data
    Map<String, Map<String, String>> timetableData = {};

    // Initialize with empty data
    for (var timeSlot in timeSlots) {
      timetableData[timeSlot] = {};
      for (var day in shortDays) {
        timetableData[timeSlot]?[day] = '';
      }
    }

    // Helper function to convert 12-hour time format to 24-hour format
    int convertTo24Hour(String time12h) {
      // Parse time like "10:00 AM" or "2:00 PM"
      final parts = time12h.split(':');
      int hour = int.tryParse(parts[0]) ?? 0;
      final isPM = time12h.toLowerCase().contains('pm');

      // Convert to 24-hour format
      if (isPM && hour < 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;

      return hour;
    }

    // Process each course
    for (var course in courses) {
      // Each course may have multiple schedule entries
      final scheduleList = course['schedule'] as List?;

      if (scheduleList == null) continue;

      // Process each schedule entry
      for (var scheduleItem in scheduleList) {
        if (scheduleItem is! Map) continue;

        // Extract day
        final day = scheduleItem['day'] as String?;
        if (day == null) continue;

        // Find the corresponding short day code
        int dayIndex = days.indexOf(day);
        if (dayIndex == -1) continue;
        final shortDay = shortDays[dayIndex];

        // Extract start and end times
        final startTimeStr = scheduleItem['startTime'] as String?;
        final endTimeStr = scheduleItem['endTime'] as String?;

        if (startTimeStr == null || endTimeStr == null) continue;

        // Convert times to 24-hour format
        final startHour = convertTo24Hour(startTimeStr);
        final endHour = convertTo24Hour(endTimeStr);

        // Course info to display in cell
        String courseInfo =
            '${course['courseId'] ?? ''} ${course['courseName'] ?? ''}\n'
            '[${course['venue'] ?? ''}] ${course['lecturerName'] ?? ''}';

        // Find matching time slots
        for (var timeSlot in timeSlots) {
          // Parse the timeSlot (e.g., "08:00-09:00")
          final slotHours = timeSlot.split('-');
          final slotStartHour = int.parse(slotHours[0].split(':')[0]);
          final slotEndHour = int.parse(slotHours[1].split(':')[0]);

          // If the course time overlaps with this slot
          if (startHour < slotEndHour && endHour > slotStartHour) {
            timetableData[timeSlot]?[shortDay] = courseInfo;
          }
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
                  for (int i = 1; i <= shortDays.length; i++)
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
                      ...shortDays.map(
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
                  ...timeSlots.map((timeSlot) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(timeSlot),
                        ),
                        ...shortDays.map((day) {
                          return pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              timetableData[timeSlot]![day] ?? '',
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

  Future<void> _downloadTimeTable() async {
    // Ensure user has enrolled courses
    if (enrolledCourses.isEmpty) {
      showSnackBar(
        context,
        'You must enroll in courses to download the timetable.',
      );
      return;
    }

    try {
      // Generate the timetable PDF
      final pdfData = await generateTimetablePdf(enrolledCourses);

      // Save the PDF instead of just displaying it
      final fileName = 'timetable_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Use printing package to save the file
      final success = await Printing.sharePdf(
        bytes: pdfData,
        filename: fileName,
      );

      if (success) {
        showSnackBar(context, 'Timetable downloaded successfully!');
      } else {
        showSnackBar(context, 'Failed to download timetable');
      }
    } catch (e) {
      showSnackBar(context, 'Error downloading timetable: $e');
    }
  }

  /// Builds the complete timetable grid using Flutter's Table widget.
  Widget buildTimetableGrid() {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    final shortDays = ['MON', 'TUE', 'WED', 'THU', 'FRI'];
    final timeSlots = [
      '08:00-09:00',
      '09:00-10:00',
      '10:00-11:00',
      '11:00-12:00',
      '12:00-13:00',
      '13:00-14:00',
      '14:00-15:00',
      '15:00-16:00',
      '16:00-17:00',
      '17:00-18:00',
    ];

    // Show loading indicator while fetching data
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your timetable...'),
          ],
        ),
      );
    }

    // Show empty state if no courses found
    if (enrolledCourses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No courses enrolled',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Your timetable will appear here once you enroll in courses',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Process the timetable data
    Map<String, Map<String, dynamic>> timetableData = {};

    // Initialize the timetable with empty data
    for (var timeSlot in timeSlots) {
      timetableData[timeSlot] = {};
      for (var day in days) {
        timetableData[timeSlot]?[day] = null;
      }
    }

    // Helper function to convert 12-hour time format to 24-hour format
    int convertTo24Hour(String time12h) {
      // Parse time like "10:00 AM" or "2:00 PM"
      final parts = time12h.split(':');
      int hour = int.tryParse(parts[0]) ?? 0;
      final isPM = time12h.toLowerCase().contains('pm');

      // Convert to 24-hour format
      if (isPM && hour < 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;

      return hour;
    }

    // Process each course
    for (var course in enrolledCourses) {
      // Each course may have multiple schedule entries
      final scheduleList = course['schedule'] as List?;

      if (scheduleList == null) continue;

      // Process each schedule entry
      for (var scheduleItem in scheduleList) {
        if (scheduleItem is! Map) continue;

        // Extract day
        final day = scheduleItem['day'] as String?;
        if (day == null) continue;

        // Find the corresponding short day code
        int dayIndex = days.indexOf(day);
        if (dayIndex == -1) continue;
        final shortDay = shortDays[dayIndex];

        // Extract start and end times
        final startTimeStr = scheduleItem['startTime'] as String?;
        final endTimeStr = scheduleItem['endTime'] as String?;

        if (startTimeStr == null || endTimeStr == null) continue;

        // Convert times to 24-hour format
        final startHour = convertTo24Hour(startTimeStr);
        final endHour = convertTo24Hour(endTimeStr);

        print(
          'Course: ${course['courseId']} - Day: $day - Start: $startHour - End: $endHour',
        );

        // Find matching time slots
        for (var timeSlot in timeSlots) {
          // Parse the timeSlot (e.g., "08:00-09:00")
          final slotHours = timeSlot.split('-');
          final slotStartHour = int.parse(slotHours[0].split(':')[0]);
          final slotEndHour = int.parse(slotHours[1].split(':')[0]);

          // If the course time overlaps with this slot
          if (startHour < slotEndHour && endHour > slotStartHour) {
            timetableData[timeSlot]?[shortDay] = {
              'courseId': course['courseId'] ?? 'Unknown',
              'courseName': course['courseName'] ?? 'Unknown Course',
              'venue': course['venue'] ?? 'TBA',
              'lecturerName': course['lecturerName'] ?? 'TBA',
            };
          }
        }
      }
    }

    // Debug: Print timetableData to verify grid population
    print('Timetable Data: $timetableData');

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      width: 110,
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'TIME',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...shortDays.map(
                      (day) => Container(
                        width: 150,
                        padding: EdgeInsets.all(8),
                        margin: EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          day,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                // Time slots and course data
                ...timeSlots.map((timeSlot) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time slot
                        Container(
                          width: 110,
                          height: 100,
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            timeSlot,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),

                        // Course slots for each day
                        ...shortDays.map((day) {
                          final courseInfo = timetableData[timeSlot]?[day];
                          final bool hasCourse = courseInfo != null;

                          return Container(
                            width: 150,
                            height: 100,
                            margin: EdgeInsets.only(left: 4),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  hasCourse
                                      ? Colors.blue.shade50
                                      : Colors.white,
                              border: Border.all(
                                color:
                                    hasCourse
                                        ? Colors.blue.shade200
                                        : Colors.grey.shade200,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child:
                                hasCourse
                                    ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${courseInfo['courseId']}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          '${courseInfo['courseName']}',
                                          style: TextStyle(fontSize: 11),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          '${courseInfo['venue']}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                        Text(
                                          '${courseInfo['lecturerName']}',
                                          style: TextStyle(fontSize: 10),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    )
                                    : SizedBox.shrink(),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEnrollmentHistroyDialog() async {
    setState(() {
      isLoading = true;
    });

    List<Map<String, dynamic>> enrollmentHistory = [];
    String errorMessage = '';

    try {
      final userId = widget.uid; // Using the widget's uid directly

      // Fetch drop requests for this student
      final dropRequestsSnapshot =
          await FirebaseFirestore.instance
              .collection('drop_requests')
              .where('studentId', isEqualTo: userId)
              .orderBy('requestDate', descending: true)
              .get();

      // Fetch enrollment data
      final enrollmentSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('student_course_enrolment')
              .get();

      // Combine both types of data into a comprehensive history
      enrollmentHistory = [
        // Add enrollment data
        ...enrollmentSnapshot.docs.map((doc) {
          final data = doc.data();
          dynamic rawDate = data['enrollmentDate'];

          // Handle both Timestamp and String formats
          Timestamp date;
          if (rawDate is Timestamp) {
            date = rawDate;
          } else if (rawDate is String) {
            date = Timestamp.fromDate(DateTime.parse(rawDate));
          } else {
            date = Timestamp.now();
          }

          return {
            'id': doc.id,
            'type': 'Enrollment',
            'courseId': data['courseId'] ?? 'Unknown',
            'courseName': data['courseName'] ?? 'Unknown Course',
            'date': date,
            'status': 'Active',
          };
        }),

        // Add drop request data
        ...dropRequestsSnapshot.docs.map((doc) {
          final data = doc.data();
          dynamic rawDate = data['requestDate'];

          // Handle both Timestamp and String formats
          Timestamp date;
          if (rawDate is Timestamp) {
            date = rawDate;
          } else if (rawDate is String) {
            date = Timestamp.fromDate(DateTime.parse(rawDate));
          } else {
            date = Timestamp.now();
          }

          return {
            'id': doc.id,
            'type': 'Drop Request',
            'courseId': data['courseId'] ?? 'Unknown',
            'courseName': data['courseName'] ?? 'Unknown Course',
            'date': date,
            'status': data['status'] ?? 'pending',
            'dropReason': data['dropReason'] ?? 'No reason provided',
          };
        }),
      ];

      // Sort by date (newest first)
      enrollmentHistory.sort((a, b) {
        final aDate = a['date'] as Timestamp;
        final bDate = b['date'] as Timestamp;
        return bDate.compareTo(aDate);
      });
    } catch (e) {
      print("Error fetching enrollment history: $e");
      errorMessage = 'Error fetching enrollment history: $e';
    } finally {
      setState(() {
        isLoading = false;
      });
    }

    // Show the enrollment history dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.history, color: Colors.blue),
              SizedBox(width: 10),
              Text('Show Enrollment and Add/Drop History'),
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
                    : enrollmentHistory.isEmpty
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
                            'No enroll transactions found',
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
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Course',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Type',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Status',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // List of enrollment history
                        Expanded(
                          child: ListView.builder(
                            itemCount: enrollmentHistory.length,
                            itemBuilder: (context, index) {
                              final item = enrollmentHistory[index];
                              final timestamp = item['date'] as Timestamp?;
                              final date =
                                  timestamp != null
                                      ? DateTime.fromMillisecondsSinceEpoch(
                                        timestamp.millisecondsSinceEpoch,
                                      )
                                      : DateTime.now();
                              final formattedDate =
                                  '${date.day}/${date.month}/${date.year}';
                              final courseId =
                                  item['courseId'] as String? ?? 'Unknown';
                              final type = item['type'] as String? ?? 'Unknown';
                              final status = item['status'] as String? ?? '';

                              // Determine colors based on type and status
                              Color statusColor;
                              if (type == 'Enrollment') {
                                statusColor = Colors.green;
                              } else if (status == 'approved') {
                                statusColor = Colors.blue;
                              } else if (status == 'rejected') {
                                statusColor = Colors.red;
                              } else {
                                statusColor = Colors.orange; // pending
                              }

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
                                      child: Text(
                                        '${courseId}\n${item['courseName'] ?? ''}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: [
                                          Icon(
                                            type == 'Enrollment'
                                                ? Icons.school
                                                : Icons.delete_outline,
                                            color:
                                                type == 'Enrollment'
                                                    ? Colors.green
                                                    : Colors.red,
                                            size: 16,
                                          ),
                                          SizedBox(width: 4),
                                          Text(type),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        type == 'Enrollment'
                                            ? 'Active'
                                            : status,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                        ),
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
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
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

                ElevatedButton.icon(
                  icon: Icon(Icons.school),
                  onPressed: _showEnrollmentHistroyDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellowAccent,
                  ),
                  label: Text(
                    'View Enrollment History',
                    style: TextStyle(color: Colors.black),
                  ),
                ),

                ElevatedButton.icon(
                  icon: Icon(Icons.payment),
                  onPressed: _showTransactionHistoryDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  label: Text(
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
