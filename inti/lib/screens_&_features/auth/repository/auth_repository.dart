import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/repositories/common_firebase_storage_repository.dart';
import 'package:inti/common/utils/utils.dart';
import 'package:inti/models/users.dart';
import 'package:inti/screens_&_features/dashboard_screen.dart';

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  ),
);

class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  AuthRepository({required this.auth, required this.firestore});

  Future<UserModel?> getCurrentUserData() async {
    if (auth.currentUser == null) {
      return null;
    }

    var userData =
        await firestore.collection('users').doc(auth.currentUser!.uid).get();

    UserModel? user;

    if (userData.data() != null) {
      user = UserModel.fromMap(userData.data()!);
    }

    return user;
  }

  Future<void> signUpWithEmail({
    required BuildContext context,
    required String email,
    required String password,
    required String username,
    File? profileImage,
    required WidgetRef ref,
  }) async {
    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;
      String photoUrl =
          'https://cdn.pixabay.com/photo/2015/04/23/22/00/tree-736885__480.jpg';

      if (profileImage != null) {
        photoUrl = await ref
            .read(CommonFirebaseStorageRepositoryProvider)
            .storeFileToFirebase('profileImage/$uid', profileImage);
      }

      Map<String, dynamic> userData = {
        'uid': uid,
        'email': email,
        'username': username,
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await firestore
          .collection('users')
          .doc(uid)
          .set(userData, SetOptions(merge: true));

      // fetch the username from firebase
      DocumentSnapshot doc = await firestore.collection('users').doc(uid).get();
      String fetchUsername = doc['username'];

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
        (route) => false,
      );

      showSnackBar(context, '$fetchUsername\'s account created successfully');
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  Future<void> signInWithEmail({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);

      DocumentSnapshot doc =
          await firestore.collection('users').doc(auth.currentUser!.uid).get();
      String fetchUsername = doc['username'];

      showSnackBar(
        context,
        'Signed in to $fetchUsername\'s account successfully',
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
        (route) => false,
      );
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  Future<void> signOut({required BuildContext context}) async {
    try {
      await auth.signOut();
      showSnackBar(context, 'User signed out successfully');
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  Stream<UserModel> userDataById(String userId) {
    return firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((event) => UserModel.fromMap(event.data()!));
  }
}
