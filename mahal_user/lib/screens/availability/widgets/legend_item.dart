import 'package:flutter/material.dart';

class LegendItem extends StatelessWidget {

  final String icon;
  final String title;
  final Color color;
  final Color? iconColor;
  final bool isCircle;

  const LegendItem({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    this.iconColor,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {

    return Row(

      children: [

        Container(

          height: 30,
          width: 30,

          alignment: Alignment.center,

          decoration: BoxDecoration(
            color: color,
            shape: isCircle
                ? BoxShape.circle
                : BoxShape.rectangle,
          ),

          child: Text(
            icon,
            style: TextStyle(
              color: iconColor ?? Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}