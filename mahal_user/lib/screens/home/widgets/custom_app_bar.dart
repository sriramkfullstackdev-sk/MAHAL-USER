import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {

    return Row(

      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: const [

        SizedBox(width: 24),

        Text(
          "Mahal Spot",

          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w400,
          ),
        ),

        Icon(
          Icons.notifications_none,
          size: 28,
        ),

      ],
    );
  }
}