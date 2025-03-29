import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:inti/common/widgets/error.dart';
import 'package:inti/screens_&_features/admin/admin_home_screen.dart';
import 'package:inti/screens_&_features/student/auth/screens/login_screen.dart';
import 'package:inti/screens_&_features/student/auth/screens/sign_up_screen.dart';
import 'package:inti/screens_&_features/student/screens/student_home_screen.dart';
import 'package:inti/screens_&_features/landing/landing_screen.dart';

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  var firebaseAuth = FirebaseAuth.instance.currentUser?.uid;
  
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(builder: (_) => LandingScreen());

    // login screen
    case LoginScreen.routeName:
      return MaterialPageRoute(builder: (_) => LoginScreen());

    // sign up screen
    case SignUpScreen.routeName:
      return MaterialPageRoute(builder: (_) => SignUpScreen());

    // student home screen
    case StudentHomeScreen.routeName:
      return MaterialPageRoute(builder: (_) => StudentHomeScreen(uid: firebaseAuth!));

    // admin home screen
    case AdminHomeScreen.routeName:
      return MaterialPageRoute(builder: (_) => AdminHomeScreen(uid: firebaseAuth!,));

    // error screen
    default:
      return MaterialPageRoute(
        builder:
            (_) =>
                Scaffold(body: ErrorScreen(error: 'This page doesn\'t exist.')),
      );
  }
}
