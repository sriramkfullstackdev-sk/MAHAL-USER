import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

class PaymentSummaryCard extends StatelessWidget {
  final String advancePaid;
  final String gstAmount;
  final String platformFee;
  final String finalAmount;

  const PaymentSummaryCard({
    super.key,
    required this.advancePaid,
    required this.gstAmount,
    required this.platformFee,
    required this.finalAmount,
  });

  Widget _summaryRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: highlight ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: highlight ? 16 : 14,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: AppColors.subtleShadow,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _summaryRow('Advance Paid', advancePaid),
          _summaryRow('GST', gstAmount),
          _summaryRow('Platform Fee', platformFee),
          const Divider(color: AppColors.border),
          _summaryRow('Final Payable Amount', finalAmount, highlight: true),
        ],
      ),
    );
  }
}
