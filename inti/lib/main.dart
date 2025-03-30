import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/provider/auth_provider.dart';
import 'package:inti/common/utils/color.dart';
import 'package:inti/common/widgets/error.dart';
import 'package:inti/common/widgets/loader.dart';
import 'package:inti/firebase_options.dart';
import 'package:inti/router.dart';
import 'package:inti/screens_&_features/admin/screens/admin_home_screen.dart';
import 'package:inti/screens_&_features/auth/screens/login_screen.dart';
import 'package:inti/screens_&_features/student/screens/student_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  Future<String> getUserRole(String uid) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) {
      final userData = userDoc.data();
      if (userData != null && userData['role'] != null) {
        return userData['role'];
      }
    }

    return 'student'; // Default role if not found
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var firebaseAuth = FirebaseAuth.instance.currentUser?.uid;
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: AppBarTheme(color: appBarColor),
      ),
      onGenerateRoute: (settings) => onGenerateRoute(settings),
      home: authState.when(
        data: (user) {
          if (user != null) {
            return FutureBuilder<String>(
              future: getUserRole(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Loader());
                } else if (snapshot.hasError) {
                  return Scaffold(
                    body: ErrorScreen(error: snapshot.error.toString()),
                  );
                } else {
                  final userRole = snapshot.data ?? 'student';
                  if (userRole == 'admin') {
                    return AdminHomeScreen(
                      uid: firebaseAuth!,
                    ); // Navigate to AdminHomeScreen
                  } else {
                    return StudentHomeScreen(
                      uid: firebaseAuth!,
                    ); // Navigate to StudentHomeScreen
                  }
                }
              },
            );
          } else {
            return LoginScreen();
          }
        },
        loading: () => const Scaffold(body: Loader()),
        error:
            (error, _) => Scaffold(body: ErrorScreen(error: error.toString())),
      ),
    );
  }
}
