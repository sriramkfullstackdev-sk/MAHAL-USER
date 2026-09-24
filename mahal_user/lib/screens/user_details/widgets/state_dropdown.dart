import 'package:flutter/material.dart';

class StateDropdown extends StatelessWidget {

  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const StateDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.symmetric(
        horizontal: 15,
      ),

      decoration: BoxDecoration(
        color: Colors.grey.shade300,
      ),

      child: DropdownButtonHideUnderline(

        child: DropdownButton<String>(

          value: value,

          hint: const Text("Select"),

          isExpanded: true,

          items: items.map((item) {

            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );

          }).toList(),

          onChanged: onChanged,
        ),
      ),
    );
  }
}