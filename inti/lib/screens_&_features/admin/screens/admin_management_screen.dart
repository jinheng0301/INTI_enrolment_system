import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/utils/color.dart';
import 'package:inti/common/utils/utils.dart';
import 'package:inti/common/widgets/drawer_list.dart';
import 'package:inti/common/widgets/error.dart';
import 'package:inti/common/widgets/loader.dart';
import 'package:inti/models/users.dart';
import 'package:inti/screens_&_features/auth/controller/auth_controller.dart';

class AdminManagementScreen extends ConsumerStatefulWidget {
  static const String routeName = '/admin-management-screen';
  final String uid;

  AdminManagementScreen({required this.uid});

  @override
  ConsumerState<AdminManagementScreen> createState() =>
      _AdminManagementScreenState();
}

class _AdminManagementScreenState extends ConsumerState<AdminManagementScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  var firebaseAuth = FirebaseAuth.instance.currentUser?.uid;
  var userData = {};
  bool isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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

  String _formatTimeStamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    if (timestamp is Timestamp) {
      DateTime dateTime = timestamp.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }

    return 'N/A';
  }

  void _showAdminProfileDetails(UserModel user) async {
    final width = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Container(
            width: width * .3,
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: tabColor.withOpacity(0.3),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                    ),
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage: NetworkImage(user.photoUrl),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                Text(
                  user.username,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                SizedBox(height: 5),

                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        user.role == 'admin'
                            ? Colors.blue.withOpacity(0.2)
                            : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: TextStyle(
                      color: user.role == 'admin' ? Colors.blue : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                SizedBox(height: 20),

                _buildInfoItem(Icons.email, 'Email', user.email),
                _buildInfoItem(Icons.person, 'User ID', user.uid),
                _buildInfoItem(
                  Icons.calendar_today,
                  'Created On',
                  _formatTimeStamp(user.createdAt),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.close, color: Colors.red),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: tabColor, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(allUsersProvider);

    return Scaffold(
      key: _scaffoldKey,

      drawer: DrawerList(uid: firebaseAuth ?? ''),

      appBar: AppBar(
        backgroundColor: tabColor,
        toolbarHeight: 80,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/admin-home-screen');
          },
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

      body:
          isLoading
              ? Center(child: Loader())
              : Column(
                children: [
                  // Admin header
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          userData.isNotEmpty && userData['username'] != null
                              ? 'Welcome ${userData['username']} to the admin management panel'
                              : 'Admin management panel',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: textColor,
                          ),
                        ),

                        SizedBox(height: 8),

                        Text(
                          'View and manage all the registered admin acounts',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),

                        SizedBox(height: 15),

                        // Search bar
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value.toLowerCase();
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search Admins...',
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Show all admins
                  Expanded(
                    child: userAsync.when(
                      loading: () => Center(child: Loader()),
                      error: (error, stackTrace) {
                        print('Error message: ${error.toString()}');
                        return ErrorScreen(error: error.toString());
                      },
                      data: (admins) {
                        // Filter admins based on search query
                        final filteredAdmins =
                            admins
                                .where(
                                  (user) => user.role == 'admin',
                                ) // First filter by role
                                .where(
                                  (
                                    user,
                                  ) => // Then filter by search query if present
                                      _searchQuery.isEmpty ||
                                      user.username.toLowerCase().contains(
                                        _searchQuery,
                                      ) ||
                                      user.email.toLowerCase().contains(
                                        _searchQuery,
                                      ),
                                )
                                .toList();
                        // First filter users by role (always applied)
                        // Then filter by search query (only if there's a search)

                        if (filteredAdmins.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchQuery.isEmpty
                                      ? Icons.people_outline
                                      : Icons.search_off,
                                  color: Colors.grey[400],
                                  size: 70,
                                ),

                                SizedBox(height: 15),

                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No students registered yet'
                                      : 'No students found for "$_searchQuery"',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          // Display all of the admin list
                          return Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20.0,
                                  vertical: 15.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Admin List (${filteredAdmins.length})',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      _searchQuery.isEmpty
                                          ? 'All Admins'
                                          : 'Filtered Admins (${filteredAdmins.length})',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: filteredAdmins.length,
                                  itemBuilder: (context, index) {
                                    final user = filteredAdmins[index];

                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 5,
                                        horizontal: 15,
                                      ),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ListTile(
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 15,
                                          vertical: 8,
                                        ),
                                        leading: CircleAvatar(
                                          backgroundImage: NetworkImage(
                                            user.photoUrl,
                                          ),
                                        ),
                                        title: Text(
                                          user.username,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user.email,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Created on: ${_formatTimeStamp(user.createdAt)}',
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              tooltip: 'View profile details',
                                              onPressed:
                                                  () =>
                                                      _showAdminProfileDetails(
                                                        user,
                                                      ),
                                              icon: Icon(
                                                Icons.visibility,
                                                color: tabColor,
                                                size: 22,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}

// final filteredUsers = _searchQuery.isEmpty
//     ? users.where((user) => user.role == 'student').toList()
//     : users.where((user) {
//       return user.username.toLowerCase().contains(_searchQuery) ||
//              user.email.toLowerCase().contains(_searchQuery);
//     }).toList();

// When search is empty: Show only users with specific role (admin/student)
// When searching: Show ALL users (admin + student) whose username/email matches the search
