import 'package:flutter/material.dart';

class DateField extends StatelessWidget {
  final TextEditingController? controller;
  final VoidCallback? onChanged;
  final bool readOnly;

  const DateField({
    super.key,
    this.controller,
    this.onChanged,
    this.readOnly = false,
  });

  Future<void> _selectDate(BuildContext context) async {
    if (readOnly) return;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && controller != null) {
      final formattedDate = '${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}';
      controller!.text = formattedDate;
      if (onChanged != null) {
        onChanged!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        height: 60,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: readOnly ? Colors.grey.shade200 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, color: readOnly ? Colors.grey.shade500 : Colors.black54, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                readOnly: true,
                onTap: readOnly ? null : () => _selectDate(context),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: 'dd/mm/yyyy',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(
                  color: readOnly ? Colors.grey.shade700 : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
