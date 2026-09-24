import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

class PaymentMethodTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const PaymentMethodTile({
    super.key,
    required this.title,
    required this.icon,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected ? const Color.fromRGBO(255, 152, 0, 0.12) : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.primaryStart : AppColors.border,
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.subtleShadow,
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primaryStart : AppColors.textSecondary, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
