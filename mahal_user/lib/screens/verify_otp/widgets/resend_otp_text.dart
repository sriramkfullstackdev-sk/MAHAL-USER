import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';

class ResendOtpText extends StatelessWidget {
  const ResendOtpText({super.key});

  @override
  Widget build(BuildContext context) {

    return GestureDetector(

      onTap: () {

        print("Resend OTP Clicked");

      },

      child: const Text(
        "Resent OTP ?",

        style: TextStyle(
          color: AppColors.resendTextColor,
          fontSize: 18,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}