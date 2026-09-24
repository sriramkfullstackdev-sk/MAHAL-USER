import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const SearchBarWidget({
    super.key,
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.searchBarColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          const SizedBox(width: 15),
          const Icon(Icons.menu),
          const SizedBox(width: 20),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: const InputDecoration(
                hintText: "search",
                border: InputBorder.none,
              ),
            ),
          ),
          const Icon(Icons.search),
          const SizedBox(width: 15),
        ],
      ),
    );
  }
}