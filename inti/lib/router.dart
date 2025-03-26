import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:inti/common/widgets/error.dart';
import 'package:inti/screens_&_features/auth/screens/login_screen.dart';
import 'package:inti/screens_&_features/auth/screens/sign_up_screen.dart';
import 'package:inti/screens_&_features/home_screen.dart';
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

    // home screen
    case HomeScreen.routeName:
      return MaterialPageRoute(builder: (_) => HomeScreen(uid: firebaseAuth!));

    // error screen
    default:
      return MaterialPageRoute(
        builder:
            (_) =>
                Scaffold(body: ErrorScreen(error: 'This page doesn\'t exist.')),
      );
  }
}
