import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

class MobileInputField extends StatelessWidget {
  final TextEditingController? controller;

  const MobileInputField({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.textFieldColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              "+91",
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const VerticalDivider(
            color: Colors.black,
            thickness: 1.5,
            width: 1,
            indent: 10,
            endIndent: 10,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  counterText: "",
                  border: InputBorder.none,
                  hintText: "Enter your phone no",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                style: const TextStyle(fontSize: 18, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
