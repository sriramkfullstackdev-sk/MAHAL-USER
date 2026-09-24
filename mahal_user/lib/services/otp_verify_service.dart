import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'fcm_service.dart';

class OtpVerifyService {
  Future<Map<String, dynamic>> verifyOtp(String mobileNumber, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobileNumber': mobileNumber, 'otp': otp}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', data['token']);
          await prefs.setString('user_role', 'USER');
          await prefs.setString('user_id', (data['user']?['user_id'] ?? data['userId'] ?? '').toString());
          await FcmService.registerToken(await FcmService.getToken());
        }
        return data; // Return full payload including userExists and user details
      }
      return {'success': false};
    } catch (e) {
      print('Error verifying OTP: $e');
      return {'success': false};
    }
  }
}
