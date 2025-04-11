import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:inti/common/widgets/error.dart';
import 'package:inti/screens_&_features/admin/screens/admin_home_screen.dart';
import 'package:inti/screens_&_features/admin/screens/manage_course_screen.dart';
import 'package:inti/screens_&_features/admin/screens/payment_verification_screen.dart';
import 'package:inti/screens_&_features/admin/screens/student_enrolment_management_screen.dart';
import 'package:inti/screens_&_features/auth/screens/login_screen.dart';
import 'package:inti/screens_&_features/auth/screens/sign_up_screen.dart';
import 'package:inti/screens_&_features/student/screens/add_drop_screen.dart';
import 'package:inti/screens_&_features/student/screens/course_enrolment_screen.dart';
import 'package:inti/screens_&_features/student/screens/payment_screen.dart';
import 'package:inti/screens_&_features/student/screens/statement_screen.dart';
import 'package:inti/screens_&_features/student/screens/student_home_screen.dart';

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  var firebaseAuth = FirebaseAuth.instance.currentUser?.uid;

  switch (settings.name) {
    // login screen
    case LoginScreen.routeName:
      return MaterialPageRoute(builder: (_) => LoginScreen());

    // sign up screen
    case SignUpScreen.routeName:
      return MaterialPageRoute(builder: (_) => SignUpScreen());

    // FOR STUDENT
    // student home screen
    case StudentHomeScreen.routeName:
      return MaterialPageRoute(
        builder: (_) => StudentHomeScreen(uid: firebaseAuth!),
      );

    // course enrolment screen
    case CourseEnrolmentScreen.routeName:
      return MaterialPageRoute(
        builder: (_) => CourseEnrolmentScreen(uid: firebaseAuth!),
      );

    // add drop screen
    case AddDropScreen.routeName:
      return MaterialPageRoute(
        builder: (_) => AddDropScreen(uid: firebaseAuth!),
      );

    // statement screen
    case StatementScreen.routeName:
      return MaterialPageRoute(
        builder: (_) => StatementScreen(uid: firebaseAuth!),
      );

    // payment screen
    case PaymentScreen.routeName:
      return MaterialPageRoute(
        builder: (_) => PaymentScreen(uid: firebaseAuth!),
      );

    // FOR ADMIN
    // admin home screen
    case AdminHomeScreen.routeName:
      return MaterialPageRoute(
        builder: (_) => AdminHomeScreen(uid: firebaseAuth!),
      );

    // manage course screen
    case ManageCourseScreen.routeName:
      return MaterialPageRoute(
        builder: (_) => ManageCourseScreen(uid: firebaseAuth!),
      );

    // student enrolment management screen
    case StudentEnrolmentManagementScreen.routeName:
      return MaterialPageRoute(
        builder: (_) => StudentEnrolmentManagementScreen(uid: firebaseAuth!),
      );

    // payment verifiaction screen
    case PaymentVerificationScreen.routeName:
      return MaterialPageRoute(
        builder: (_) => PaymentVerificationScreen(uid: firebaseAuth!),
      );

    // error screen
    default:
      return MaterialPageRoute(
        builder:
            (_) =>
                Scaffold(body: ErrorScreen(error: 'This page doesn\'t exist.')),
      );
  }
}
