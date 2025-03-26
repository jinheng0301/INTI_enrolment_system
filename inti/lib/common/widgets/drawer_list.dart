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
              child: Text('Conlan7frim!'),
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
          ListTile(
            onTap: () {},
            title: Text('Enrolment', textAlign: TextAlign.center),
          ),
          ListTile(
            onTap: () {},
            title: Text('Add / Drop Courses', textAlign: TextAlign.center),
          ),
          ListTile(
            onTap: () {},
            title: Text('Statement of Account', textAlign: TextAlign.center),
          ),
          ListTile(
            onTap: () {},
            title: Text('Payment', textAlign: TextAlign.center),
          ),
          ListTile(
            onTap: () {},
            title: Text('Account Management', textAlign: TextAlign.center),
          ),
          ListTile(
            onTap: _showDialog,
            title: Text('Sign Out!', textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}
