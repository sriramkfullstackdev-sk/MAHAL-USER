import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String? hintText;
  final TextEditingController? controller;

  const CustomTextField({super.key, this.hintText, this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,

        hintStyle: const TextStyle(color: Colors.grey, fontSize: 18),

        filled: true,

        fillColor: Colors.grey.shade300,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),

          borderSide: BorderSide.none,
        ),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 18,
        ),
      ),
    );
  }
}
