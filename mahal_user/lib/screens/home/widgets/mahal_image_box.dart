import 'dart:convert';
import 'package:flutter/material.dart';

class MahalImageBox extends StatelessWidget {
  final String? imageBase64;

  const MahalImageBox({super.key, this.imageBase64});

  String? get firstImageBase64 {
    if (imageBase64 == null || imageBase64!.trim().isEmpty) {
      return null;
    }

    final imageList = imageBase64!
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    return imageList.isEmpty ? null : imageList.first;
  }

  @override
  Widget build(BuildContext context) {
    final firstImage = firstImageBase64;

    return Container(
      width: 95,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFC9A3A3),
      ),
      clipBehavior: Clip.antiAlias,
      child: firstImage != null
          ? Image.memory(
              base64Decode(firstImage),
              fit: BoxFit.cover,
              width: 95,
              height: 70,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Text(
                    "MAHAL\nPHOTOS",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                );
              },
            )
          : const Center(
              child: Text(
                "MAHAL\nPHOTOS",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
    );
  }
}
