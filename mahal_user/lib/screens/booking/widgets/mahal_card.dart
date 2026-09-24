import 'package:flutter/material.dart';

import 'photo_grid.dart';
import 'mahal_details.dart';

import '../../../models/mahal_model.dart';

class MahalCard extends StatelessWidget {
  final MahalModel mahal;

  const MahalCard({super.key, required this.mahal});

  @override
  Widget build(BuildContext context) {

    return Container(

      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(

        border: Border.all(
          color: Colors.black54,
        ),

        borderRadius: BorderRadius.circular(25),
      ),

      child: Column(

        children: [

          /// TITLE
          Text(
            mahal.mahalName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 10),

          /// SUBTITLE
          Text(
            "MAHAL PHOTOS",
            style: TextStyle(
              fontSize: 14,
            ),
          ),

          SizedBox(height: 25),

          /// PHOTOS
          PhotoGrid(mahal: mahal),

          SizedBox(height: 30),

          /// DETAILS
          MahalDetails(mahal: mahal),
        ],
      ),
    );
  }
}