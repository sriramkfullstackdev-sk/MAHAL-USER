import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'fcm_service.dart';

class AuthService {
  Future<bool> hasSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, dynamic>> checkMobile(String mobileNumber) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/check-mobile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobileNumber': mobileNumber}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'exists': data['exists'] == true,
          'role': data['role'],
          'userId': data['userId'],
        };
      }

      return {'success': false, 'message': data['message'] ?? 'Unable to check mobile'};
    } catch (e) {
      print('Error checking mobile: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  Future<Map<String, dynamic>> registerUser({
    required String mobileNumber,
    required String name,
    required String address,
    required String state,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobileNumber': mobileNumber,
          'name': name,
          'address': address,
          'state': state,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', data['token']);
          await prefs.setString('user_role', 'USER');
          await prefs.setString('user_id', (data['user']?['user_id'] ?? data['userId'] ?? '').toString());
          await FcmService.registerToken(await FcmService.getToken());
        }
        return {'success': true};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Registration failed'
      };
    } catch (e) {
      print('Error registering user: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/auth/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(response.body);
      return response.statusCode == 200
          ? data
          : {'success': false, 'message': data['message'] ?? 'Unable to load profile'};
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_role');
    await prefs.remove('user_id');
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String mobileNumber,
    required String address,
  }) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'mobileNumber': mobileNumber,
          'address': address,
        }),
      );
      final data = jsonDecode(response.body);
      return response.statusCode == 200
          ? data
          : {'success': false, 'message': data['message'] ?? 'Unable to update profile'};
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }
}
