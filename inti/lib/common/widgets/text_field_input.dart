import 'package:flutter/material.dart';

class TextFieldInput extends StatelessWidget {
  late final TextEditingController textEditingController;
  late final bool isPass;
  late final TextInputType textInputType;
  late final String hintText;

  TextFieldInput({
    required this.hintText,
    this.isPass = false,
    required this.textEditingController,
    required this.textInputType,
  });

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderSide: Divider.createBorderSide(context),
    );

    return TextField(
      controller: textEditingController,
      decoration: InputDecoration(
        hintText: hintText,
        border: inputBorder,
        focusedBorder: inputBorder,
        enabledBorder: inputBorder,
        filled: true,
        contentPadding: const EdgeInsets.all(8),
      ),
      keyboardType: textInputType,
      obscureText: isPass,
    );
  }
}
