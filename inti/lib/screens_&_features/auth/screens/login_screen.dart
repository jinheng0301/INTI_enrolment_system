import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/utils/utils.dart';
import 'package:inti/common/widgets/loader.dart';
import 'package:inti/common/widgets/text_field_input.dart';
import 'package:inti/screens_&_features/auth/controller/auth_controller.dart';
import 'package:inti/screens_&_features/auth/screens/sign_up_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  static const routeName = '/login-screen';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
  }

  void logIn() {
    try {
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        showSnackBar(context, 'Please fill all the fields');
        return;
      }

      setState(() {
        isLoading = true;
      });

      ref
          .read(authControllerProvider)
          .signInWithEmail(
            context: context,
            email: _emailController.text,
            password: _passwordController.text,
          )
          .then((value) {
            setState(() {
              isLoading = false;
            });
          });

      clearForm();
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  void clearForm() {
    _emailController.clear();
    _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Container(
          padding:
              width > 600
                  ? EdgeInsets.symmetric(horizontal: width * 0.3)
                  : EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40),

              Image.asset('images/inti_logo.png', height: 100),

              SizedBox(height: 60),

              // Email Field
              TextFieldInput(
                controller: _emailController,
                hintText: 'Enter your email...',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Password Field
              TextFieldInput(
                controller: _passwordController,
                hintText: 'Enter your password...',
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),

              SizedBox(height: 30),

              InkWell(
                onTap: logIn,
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    color: Colors.lightBlue,
                  ),
                  child:
                      isLoading
                          ? Center(child: Loader())
                          : Text(
                            'Sign In!',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                ),
              ),

              Flexible(flex: 2, child: Container()),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Don\'t have an account?'),
                  ),
                  SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => SignUpScreen()),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Colors.lightBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
