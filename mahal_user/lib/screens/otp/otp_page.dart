import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/otp_service.dart';
import '../../widgets/user_app_bar.dart';
import 'widgets/mobile_input_field.dart';
import 'widgets/send_otp_button.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController _mobileController = TextEditingController();
  final OtpService _otpService = OtpService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleSendOtp() async {
    final mobile = _mobileController.text.trim();
    if (mobile.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit mobile number')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final checkResult = await _authService.checkMobile(mobile);
    if (!mounted) return;
    if (checkResult['success'] != true) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(checkResult['message'] ?? 'Unable to check mobile')),
      );
      return;
    }

    final result = await _otpService.sendOtp(mobile);
    setState(() => _isLoading = false);

    if (result == 'success') {
      Navigator.pushNamed(context, AppRoutes.verifyOtpPage, arguments: mobile);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: const UserAppBar(title: 'OTP'),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MobileInputField(controller: _mobileController),
              const SizedBox(height: 50),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                SendOtpButton(onTap: _handleSendOtp),
            ],
          ),
        ),
      ),
    );
  }
}

