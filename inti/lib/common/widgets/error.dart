import 'package:flutter/material.dart';

class ErrorScreen extends StatelessWidget {
  late final String error;

  ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Error: $error'),
      ),
    );
  }
}
