import 'package:flutter/material.dart';

import 'dart:convert';
import '../../../models/mahal_model.dart';
import 'full_screen_image_viewer.dart';

class PhotoGrid extends StatelessWidget {
  final MahalModel mahal;

  const PhotoGrid({super.key, required this.mahal});

  @override
  Widget build(BuildContext context) {
    List<String> imageList = [];
    if (mahal.imageBase64 != null && mahal.imageBase64!.isNotEmpty) {
      if (mahal.imageBase64!.contains(',')) {
        imageList = mahal.imageBase64!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      } else {
        imageList = [mahal.imageBase64!.trim()];
      }
    }

    if (imageList.length < 6) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black),
        ),
        child: Center(
          child: Text(
            "Database-il 6 photos illai.\nOnly ${imageList.length} photo(s) available.",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.2,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullScreenImageViewer(
                  imageList: imageList,
                  initialIndex: index,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              image: DecorationImage(
                image: MemoryImage(base64Decode(imageList[index])),
                fit: BoxFit.cover,
              ),
              border: Border.all(color: Colors.black),
            ),
          ),
        );
      },
    );
  }
}