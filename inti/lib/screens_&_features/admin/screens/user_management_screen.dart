import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/utils/color.dart';
import 'package:inti/common/utils/utils.dart';
import 'package:inti/common/widgets/drawer_list.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  static const routeName = '/user-management-screen';
  final String uid;

  UserManagementScreen({required this.uid});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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

  @override
  Widget build(BuildContext context) {
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

      body: Container(),
    );
  }
}
