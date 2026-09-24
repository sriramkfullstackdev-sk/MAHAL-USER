import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../services/otp_verify_service.dart';
import '../../widgets/user_app_bar.dart';
import 'widgets/otp_box_row.dart';
import 'widgets/resend_otp_text.dart';
import 'widgets/verify_otp_button.dart';

class VerifyOtpPage extends StatefulWidget {
  const VerifyOtpPage({super.key});

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final OtpVerifyService _verifyService = OtpVerifyService();
  String _currentOtp = '';
  bool _isLoading = false;

  void _handleVerify(String mobileNumber) async {
    if (_currentOtp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await _verifyService.verifyOtp(mobileNumber, _currentOtp);
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (result['userExists'] == true) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.homePage, (route) => false);
        return;
      }

      final args = {
        'mobileNumber': mobileNumber,
        'userExists': result['userExists'],
        'user': result['user'],
      };
      Navigator.pushNamed(context, AppRoutes.userDetailsPage, arguments: args);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobileNumber = ModalRoute.of(context)?.settings.arguments as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: const UserAppBar(title: 'Verify OTP', showBack: true),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OtpBoxRow(
                onOtpChanged: (otp) {
                  _currentOtp = otp;
                },
              ),
              const SizedBox(height: 30),
              const ResendOtpText(),
              const SizedBox(height: 40),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                VerifyOtpButton(
                  onTap: () => _handleVerify(mobileNumber),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

