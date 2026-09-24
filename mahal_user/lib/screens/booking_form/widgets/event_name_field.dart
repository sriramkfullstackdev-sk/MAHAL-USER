import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

class EventNameField extends StatelessWidget {
  final TextEditingController? controller;

  const EventNameField({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: "Enter Your Event Name",
        hintStyle: const TextStyle(color: Colors.black54, fontSize: 16),
        filled: true,
        fillColor: AppColors.textFieldColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    );
  }
}
