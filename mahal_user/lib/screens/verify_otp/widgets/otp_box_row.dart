import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

class OtpBoxRow extends StatefulWidget {
  final ValueChanged<String>? onOtpChanged;

  const OtpBoxRow({super.key, this.onOtpChanged});

  @override
  State<OtpBoxRow> createState() => _OtpBoxRowState();
}

class _OtpBoxRowState extends State<OtpBoxRow> {
  final List<TextEditingController> _controllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 3) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        _focusNodes[index].unfocus();
      }
    } else {
      if (index > 0) {
        FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
      }
    }

    String otp = _controllers.map((c) => c.text).join();
    if (widget.onOtpChanged != null) {
      widget.onOtpChanged!(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          width: 50,
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.textFieldColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            onChanged: (val) => _onChanged(val, index),
            decoration: const InputDecoration(
              counterText: "",
              border: InputBorder.none,
            ),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        );
      }),
    );
  }
}
