import 'package:flutter/material.dart';

class BookNowButton extends StatelessWidget {

  const BookNowButton({super.key});

  @override
  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),

      decoration: BoxDecoration(

        color: Colors.green.shade100,

        borderRadius: BorderRadius.circular(15),

        boxShadow: const [

          BoxShadow(
            color: Colors.black26,
            blurRadius: 5,
            offset: Offset(0, 4),
          ),
        ],
      ),

      child: const Text(
        "BOOK NOW",
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey,
        ),
      ),
    );
  }
}