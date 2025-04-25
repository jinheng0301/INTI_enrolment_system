import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/models/users.dart';
import 'package:inti/screens_&_features/auth/repository/auth_repository.dart';

// StreamProvider to listen to authentication state
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final authControllerProvider = Provider((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository: authRepository, ref: ref);
});

final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final authController = ref.watch(authControllerProvider);
  return authController.getAllUsers();
});

class AuthController {
  final AuthRepository authRepository;
  final Ref ref;

  AuthController({required this.authRepository, required this.ref});

  // get user data from firebase
  Future<UserModel?> getUserData() async {
    UserModel? user = await authRepository.getCurrentUserData();
    return user;
  }

  // sign up with email and password
  Future<void> signUpWithEmail({
    required BuildContext context,
    required String email,
    required String password,
    required String username,
    required WidgetRef ref,
    File? profileImage,
    required String role,
  }) async {
    await authRepository.signUpWithEmail(
      context: context,
      email: email,
      password: password,
      username: username,
      role: role,
      ref: ref,
      profileImage: profileImage,
    );

    // Navigate based on role
    if (role == 'student') {
      Navigator.pushReplacementNamed(context, '/home-screen');
    } else if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin-home-screen');
    }
  }

  // sign in with email and password
  Future<void> signInWithEmail({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    return await authRepository.signInWithEmail(
      context: context,
      email: email,
      password: password,
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required BuildContext context,
  }) async {
    await authRepository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      context: context,
    );
  }

  Future<void> signOut({required BuildContext context}) async {
    return await authRepository.signOut(context: context);
  }

  Stream<UserModel> userDatabyId(String userId) {
    return authRepository.userDataById(userId);
  }

  Stream<List<UserModel>> getAllUsers() {
    return authRepository.getAllUsers();
  }
}
