import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

class PayNowButton extends StatelessWidget {
  final VoidCallback onTap;

  const PayNowButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [AppColors.primaryStart, AppColors.primaryEnd],
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.subtleShadow,
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'PAY NOW',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
