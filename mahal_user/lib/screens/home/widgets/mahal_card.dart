import 'package:flutter/material.dart';

import '../../../models/mahal_model.dart';

import '../../../utils/app_colors.dart';

import 'booking_button.dart';
import 'mahal_image_box.dart';

class MahalCard extends StatelessWidget {
  final MahalModel mahal;

  const MahalCard({super.key, required this.mahal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderColor),

        borderRadius: BorderRadius.circular(25),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          MahalImageBox(imageBase64: mahal.imageBase64),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  mahal.mahalName,

                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    Text(mahal.price, style: const TextStyle(fontSize: 16)),

                    const SizedBox(width: 5),

                    const Text("perday"),
                  ],
                ),

                const SizedBox(height: 5),

                Text(mahal.location),
              ],
            ),
          ),

          BookingButton(mahal: mahal),
        ],
      ),
    );
  }
}
