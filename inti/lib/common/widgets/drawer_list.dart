import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/utils/utils.dart';
import 'package:inti/screens_&_features/auth/controller/auth_controller.dart';

class DrawerList extends ConsumerStatefulWidget {
  final String uid;

  DrawerList({required this.uid});
  @override
  ConsumerState<DrawerList> createState() => _DrawerListState();
}

class _DrawerListState extends ConsumerState<DrawerList> {
  var userData = {};
  bool isLoading = false;
  String userRole = 'student';

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

      if (userSnap.exists) {
        userData = userSnap.data()!;
        userRole = userData['role'] ?? 'student';
      }

      setState(() {});
    } catch (e) {
      showSnackBar(context, e.toString());
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _showDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Are you sure want to sign out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Call the sign-out method from the AuthController
                  await ref
                      .read(authControllerProvider)
                      .signOut(context: context);
                } catch (e) {
                  showSnackBar(context, 'Failed to sign out: $e');
                }
              },
              child: Text('Conlan7firm!'),
            ),
          ],
        );
      },
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    // final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Drawer(
      child: ListView(
        children: [
          SizedBox(
            height: height * 0.3,
            child: DrawerHeader(
              decoration: BoxDecoration(color: Colors.greenAccent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  userData.isNotEmpty && userData['photoUrl'] != null
                      ? CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey,
                        backgroundImage: NetworkImage(userData['photoUrl']),
                      )
                      : CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, size: 40),
                      ),

                  SizedBox(height: 8),
                  Spacer(),

                  Text(
                    userData.isNotEmpty && userData['username'] != null
                        ? userData['username']
                        : 'Unknown User', // ✅ Handle null case
                    style: TextStyle(fontSize: 20),
                  ),

                  Text(
                    userData.isNotEmpty && userData['email'] != null
                        ? userData['email']
                        : 'No Email',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          if (userRole == 'student') ...[
            ListTile(
              onTap: () {
                Navigator.pushNamed(context, '/course-enrolment-screen');
              },
              leading: Icon(Icons.school),
              title: Text('Course Enrollment'),
            ),
            ListTile(
              onTap: () {
                Navigator.pushNamed(context, '/add-drop-screen');
              },
              leading: Icon(Icons.playlist_add),
              title: Text('Add / Drop Courses'),
            ),
            ListTile(
              onTap: () {
                Navigator.pushNamed(context, '/statement-screen');
              },
              leading: Icon(Icons.receipt),
              title: Text('Statement of Account'),
            ),
            ListTile(
              onTap: () {},
              leading: Icon(Icons.payment),
              title: Text('Payment'),
            ),
            ListTile(
              onTap: () {},
              leading: Icon(Icons.settings),
              title: Text('Account Management'),
            ),
          ] else if (userRole == 'admin') ...[
            ListTile(
              onTap: () {
                Navigator.pushNamed(context, '/manage-course-screen');
              },
              leading: Icon(Icons.library_books),
              title: Text('Manage Courses'),
            ),
            ListTile(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/student-enrolment-management-screen',
                );
              },
              leading: Icon(Icons.person_add),
              title: Text('Student Enrolment Management'),
            ),
            ListTile(
              onTap: () {},
              leading: Icon(Icons.payment),
              title: Text('Payment Verification'),
            ),
            ListTile(
              onTap: () {},
              leading: Icon(Icons.analytics),
              title: Text('Reports & Analytics'),
            ),
            ListTile(
              onTap: () {},
              leading: Icon(Icons.admin_panel_settings),
              title: Text('User Management'),
            ),
          ],

          ListTile(
            onTap: _showDialog,
            leading: Icon(Icons.logout),
            title: Text('Sign Out!'),
          ),
        ],
      ),
    );
  }
}
