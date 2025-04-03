import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/utils/color.dart';
import 'package:inti/common/widgets/drawer_list.dart';
import 'package:inti/common/widgets/error.dart';
import 'package:inti/common/widgets/loader.dart';
import 'package:inti/models/drop_request.dart';
import 'package:inti/screens_&_features/admin/controllers/student_enrolment_management_controller.dart';

final dropRequestsProvider = StreamProvider.autoDispose<List<DropRequest>>((
  ref,
) {
  return FirebaseFirestore.instance
      .collection('drop_requests')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => DropRequest.fromFirestore(doc)).toList(),
      );
});

class StudentEnrolmentManagementScreen extends ConsumerStatefulWidget {
  static const routeName = '/student-enrolment-management-screen';
  final String uid;

  const StudentEnrolmentManagementScreen({super.key, required this.uid});

  @override
  ConsumerState<StudentEnrolmentManagementScreen> createState() =>
      _StudentEnrolmentManagementState();
}

class _StudentEnrolmentManagementState
    extends ConsumerState<StudentEnrolmentManagementScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic> userData = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userSnap =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .get();
    setState(() => userData = userSnap.data() ?? {});
  }

  // Widget _buildEnrollmentTable(
  //   List<EnrollmentForApproveAndReject> enrollments,
  // ) {
  //   return SingleChildScrollView(
  //     scrollDirection: Axis.vertical,
  //     child: DataTable(
  //       columns: const [
  //         DataColumn(label: Text('Student ID')),
  //         DataColumn(label: Text('Name')),
  //         DataColumn(label: Text('Course')),
  //         DataColumn(label: Text('Status')),
  //         DataColumn(label: Text('Drop Reason')),
  //         DataColumn(label: Text('Actions')),
  //       ],
  //       rows:
  //           enrollments
  //               .map(
  //                 (enrollment) => DataRow(
  //                   cells: [
  //                     DataCell(Text(enrollment.studentId)),
  //                     DataCell(Text(enrollment.studentName)),
  //                     DataCell(Text(enrollment.courseName)),
  //                     DataCell(Text(enrollment.status)),
  //                     DataCell(
  //                       Text(enrollment.dropReason ?? 'N/A'),
  //                     ), // Display drop reason
  //                     DataCell(
  //                       Row(
  //                         children: [
  //                           ElevatedButton(
  //                             onPressed:
  //                                 () => ref
  //                                     .read(studentEnrolmentManagementProvider)
  //                                     .approveDropRequest(enrollment.id),
  //                             style: ElevatedButton.styleFrom(
  //                               backgroundColor: Colors.green,
  //                             ),
  //                             child: const Text('Approve'),
  //                           ),
  //                           const SizedBox(width: 8),
  //                           ElevatedButton(
  //                             onPressed:
  //                                 () => ref
  //                                     .read(studentEnrolmentManagementProvider)
  //                                     .rejectDropRequest(enrollment.id),
  //                             style: ElevatedButton.styleFrom(
  //                               backgroundColor: Colors.red,
  //                             ),
  //                             child: const Text('Reject'),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               )
  //               .toList(),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final dropRequests = ref.watch(dropRequestsProvider);

    return Scaffold(
      key: _scaffoldKey,
      drawer: DrawerList(uid: user?.uid ?? ''),
      appBar: AppBar(
        backgroundColor: tabColor,
        toolbarHeight: 80,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/admin-home-screen'),
          child: Image.asset('images/inti_logo.png', height: 40),
        ),
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
            Padding(
              padding: const EdgeInsets.all(25),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 5,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Text(
                  userData.isNotEmpty && userData['username'] != null
                      ? '${userData['username']} admin, you can manage all the student pending courses.'
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
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: dropRequests.when(
                loading: () => const Loader(),
                error: (error, stack) => ErrorScreen(error: error.toString()),
                data:
                    (requests) => ListView.builder(
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final request = requests[index];

                        return Card(
                          child: ListTile(
                            title: Text(request.courseName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Student: ${request.studentName}'),
                                Text('Reason: ${request.dropReason}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.check, color: Colors.green),
                                  onPressed:
                                      () => ref
                                          .read(
                                            studentEnrolmentManagementProvider,
                                          )
                                          .approveDropRequest(request.id),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.red),
                                  onPressed:
                                      () => ref
                                          .read(
                                            studentEnrolmentManagementProvider,
                                          )
                                          .rejectDropRequest(request.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
