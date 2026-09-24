import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';

class OtpBox extends StatefulWidget {
  final Function(String)? onChanged;
  final Function()? onBackspace;
  final FocusNode? focusNode;

  const OtpBox({Key? key, this.onChanged, this.onBackspace, this.focusNode})
    : super(key: key);

  @override
  State<OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<OtpBox> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.otpCircleColor, width: 2),
      ),
      child: TextField(
        controller: _controller,
        focusNode: widget.focusNode,
        maxLength: 1,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            widget.onChanged?.call(value);
          } else {
            widget.onBackspace?.call();
          }
        },
      ),
    );
  }
}
