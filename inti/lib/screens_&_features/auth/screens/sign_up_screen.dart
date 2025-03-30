import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/common/utils/utils.dart';
import 'package:inti/common/widgets/loader.dart';
import 'package:inti/common/widgets/text_field_input.dart';
import 'package:inti/screens_&_features/auth/controller/auth_controller.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  static const routeName = '/signup-screen';

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  File? _profileImage;
  bool isLoading = false;
  String _selectedRole = 'student'; // Default role

  void pickImage() async {
    final file = await pickImageFromGallery(context);
    if (file != null) {
      _profileImage = file;
    }
    setState(() {});
  }

  void signUp() {
    try {
      if (_emailController.text.isEmpty ||
          _passwordController.text.isEmpty ||
          _confirmPasswordController.text.isEmpty ||
          _usernameController.text.isEmpty) {
        showSnackBar(context, 'Please fill all the fields');
        return;
      }

      if (_passwordController.text.length < 6) {
        showSnackBar(context, 'Password must be at least 6 characters long');
        return;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        showSnackBar(context, 'Password does not match');
        return;
      }

      setState(() {
        isLoading = true;
      });

      ref
          .read(authControllerProvider)
          .signUpWithEmail(
            context: context,
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            username: _usernameController.text.trim(),
            role: _selectedRole,
            ref: ref,
            profileImage: _profileImage,
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
    _confirmPasswordController.clear();
    _usernameController.clear();
    _profileImage = null;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 32),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 40),

                Image.asset('images/inti_logo.png', height: 100),

                SizedBox(height: 20),

                Text(
                  'Sign up a new INTI account. ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                SizedBox(height: 20),

                Stack(
                  children: [
                    _profileImage != null
                        ? CircleAvatar(
                          radius: 64,
                          backgroundImage: MemoryImage(
                            _profileImage!.readAsBytesSync(),
                          ),
                        )
                        : CircleAvatar(
                          radius: 64,
                          backgroundImage: NetworkImage(
                            'https://www.pngitem.com/pimgs/m/146-1468479_my-profile-icon-blank-profile-picture-circle-hd.png',
                          ),
                        ),
                    Positioned(
                      bottom: -10,
                      left: 80,
                      child: IconButton(
                        onPressed: pickImage,
                        icon: Icon(Icons.add_a_photo),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                TextFieldInput(
                  hintText: 'Enter your username...',
                  textEditingController: _usernameController,
                  textInputType: TextInputType.text,
                ),

                SizedBox(height: 20),

                // Add the DropdownButton for role selection
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  items:
                      <String>['student', 'admin'].map((String role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(
                            role[0].toUpperCase() +
                                role.substring(1), // Capitalize first letter
                          ),
                        );
                      }).toList(),
                  onChanged: (String? newRole) {
                    if (newRole != null) {
                      setState(() {
                        _selectedRole = newRole;
                      });
                    }
                  },
                ),

                SizedBox(height: 20),

                TextFieldInput(
                  hintText: 'Enter your email...',
                  textEditingController: _emailController,
                  textInputType: TextInputType.emailAddress,
                ),

                SizedBox(height: 20),

                TextFormField(
                  controller: _passwordController,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Enter your password...',
                    border: OutlineInputBorder(
                      borderSide: Divider.createBorderSide(context),
                    ),
                  ),
                  validator: (value) {
                    if (value!.isEmpty || value.length < 6) {
                      showSnackBar(
                        context,
                        'Password must be at least 6 characters long',
                      );
                    }
                    return null;
                  },
                ),

                SizedBox(height: 20),

                TextFormField(
                  controller: _confirmPasswordController,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Confirm your password...',
                    border: OutlineInputBorder(
                      borderSide: Divider.createBorderSide(context),
                    ),
                  ),
                  validator: (value) {
                    if (value!.isEmpty || value != _passwordController.text) {
                      showSnackBar(context, 'Password does not match');
                    }
                    return null;
                  },
                ),

                SizedBox(height: 30),

                InkWell(
                  onTap: signUp,
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
                              'Sign Up!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
