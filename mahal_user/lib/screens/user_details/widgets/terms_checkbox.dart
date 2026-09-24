import 'package:flutter/material.dart';

class TermsCheckbox extends StatelessWidget {

  final bool value;
  final ValueChanged<bool?> onChanged;

  const TermsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {

    return Row(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Checkbox(
          value: value,
          onChanged: onChanged,
        ),

        const Expanded(

          child: Padding(
            padding: EdgeInsets.only(top: 12),

            child: Text(
              "I confirm that all entered details are correct\nand I agree to the Terms & Conditions",
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}