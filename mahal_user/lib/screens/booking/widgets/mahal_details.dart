import 'package:flutter/material.dart';

import '../../../models/mahal_model.dart';

class MahalDetails extends StatelessWidget {
  final MahalModel mahal;

  const MahalDetails({super.key, required this.mahal});

  @override
  Widget build(BuildContext context) {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Text(
          mahal.mahalName,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 10),

        Row(

          children: [

            Text(
              mahal.price,
              style: TextStyle(
                fontSize: 18,
              ),
            ),

            SizedBox(width: 5),

            Text(
              "perday",
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ),

        SizedBox(height: 5),

        Text(
          mahal.location,
          style: TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}