import 'package:flutter/material.dart';

class FinishButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String text;

  const FinishButton({
    super.key,
    this.onTap,
    this.text = 'Submit',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 35,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [
              Colors.orange,
              Colors.deepOrange,
            ],
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 5,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            color: Color.fromARGB(255, 18, 15, 15),
          ),
        ),
      ),
    );
  }
}
