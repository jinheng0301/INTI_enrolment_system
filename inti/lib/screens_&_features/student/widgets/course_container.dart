import 'package:flutter/material.dart';

class CourseContainer extends StatelessWidget {
  late final String courseName;
  late final String courseCode;
  late final String lecturerName;
  late final String schedule;
  late final String venue;
  late final String availableSeats;
  late final int creditHours;
  late final VoidCallback onEnroll;

  CourseContainer({
    required this.courseName,
    required this.courseCode,
    required this.lecturerName,
    required this.schedule,
    required this.venue,
    required this.availableSeats,
    required this.creditHours,
    required this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$courseCode: $courseName',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${creditHours.toString()} Credits',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),

            SizedBox(height: 10),

            Text(
              'Lecturer: $lecturerName',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
            ),
            Text(
              'Schedule: $schedule',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
            ),
            Text(
              'Class Venue: $venue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
            ),
            Text(
              'Available Seats: $availableSeats',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
            ),

            SizedBox(height: 10),

            InkWell(
              onTap: onEnroll,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  'Enroll Now!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
