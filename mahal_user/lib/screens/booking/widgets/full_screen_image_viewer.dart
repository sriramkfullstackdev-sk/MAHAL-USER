import 'package:flutter/material.dart';
import 'dart:convert';

class FullScreenImageViewer extends StatelessWidget {
  final List<String> imageList;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.imageList,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    PageController pageController = PageController(initialPage: initialIndex);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: PageView.builder(
        controller: pageController,
        itemCount: imageList.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.memory(
                base64Decode(imageList[index]),
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}
