import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class OtpService {
  Future<String> sendOtp(String mobileNumber) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobileNumber': mobileNumber}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return 'success';
      } else {
        return 'Server Error: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      print('Error sending OTP: $e');
      return 'Network Error: $e';
    }
  }
}

