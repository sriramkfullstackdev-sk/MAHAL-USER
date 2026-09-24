import 'package:flutter/material.dart';

class TimeField extends StatelessWidget {
  final TextEditingController? controller;
  final bool readOnly;

  const TimeField({
    super.key,
    this.controller,
    this.readOnly = true,
  });

  Future<void> _selectTime(BuildContext context) async {
    if (readOnly) return;
    final localizations = MaterialLocalizations.of(context);
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null && controller != null) {
      final formattedTime = localizations.formatTimeOfDay(pickedTime, alwaysUse24HourFormat: false);
      controller!.text = formattedTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: readOnly ? null : () => _selectTime(context),
      child: Container(
        height: 60,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: readOnly ? Colors.grey.shade200 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(15),
        ),
        child: TextField(
          controller: controller,
          readOnly: true,
          enabled: !readOnly,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            hintText: 'hh:mm AM/PM',
            border: InputBorder.none,
            disabledBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            hintStyle: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          style: TextStyle(
            color: readOnly ? Colors.grey.shade800 : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
