import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/utils/color.dart';
import 'package:inti/common/utils/utils.dart';
import 'package:inti/common/widgets/drawer_list.dart';
import 'package:inti/common/widgets/error.dart';
import 'package:inti/common/widgets/loader.dart';
import 'package:inti/screens_&_features/admin/controllers/student_enrolment_management_controller.dart';

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
  var userData = {};
  bool isLoading = false;
  bool isAdmin = false; // Admin status

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  // ✅ Fetch User Data from Firestore
  void getUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      var userSnap =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.uid)
              .get();

      if (userSnap.exists) {
        userData = userSnap.data()!;

        // Check admin status using Firestore 'role' field
        isAdmin = userData['role'] == 'admin';

        setState(() {
          isLoading = false;
        });
      } else {
        showSnackBar(context, "User data not found.");
      }
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  // ✅ Fetch Drop Requests (Only if Admin)
  Stream<List<Map<String, dynamic>>> fetchDropRequests() {
    if (!isAdmin) {
      return Stream.value([]); // Return an empty list if not admin
    }

    return FirebaseFirestore.instance
        .collection('drop_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'studentId': data['studentId'],
              'courseId': data['courseId'],
              'courseName': data['courseName'],
              'studentName': data['studentName'],
              'dropReason': data['dropReason'],
              'requestDate': data['timestamp'],
            };
          }).toList();
        });
  }

  @override
  Widget build(BuildContext context) {
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
      body: Column(
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
                    ? '${userData['username']} admin, you can manage all student pending courses.'
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

          isAdmin
              ? Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: fetchDropRequests(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Loader();
                    } else if (snapshot.hasError) {
                      return ErrorScreen(error: snapshot.error.toString());
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No pending drop requests.'));
                    }

                    final requests = snapshot.data!;

                    return ListView.builder(
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final request = requests[index];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            title: Text(
                              request['courseName'] ?? 'Unknown Course',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Student: ${request['studentName']}'),
                                Text('Reason: ${request['dropReason']}'),
                                Text(
                                  'Requested on: ${request['requestDate']?.toDate().toLocal()}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.check, color: Colors.green),
                                  onPressed: () {
                                    ref
                                        .read(
                                          studentEnrolmentManagementProvider,
                                        )
                                        .approveDropRequest(
                                          request['id'],
                                          context,
                                        );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.red),
                                  onPressed: () {
                                    ref
                                        .read(
                                          studentEnrolmentManagementProvider,
                                        )
                                        .rejectDropRequest(
                                          request['id'],
                                          context,
                                        );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              )
              : Center(
                child: Text(
                  'Access Denied: You are not an admin.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
