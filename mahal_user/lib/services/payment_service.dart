import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class PaymentService {
  Future<Map<String, dynamic>> processPayment({
    required String bookingId,
    required String amount,
    required String paymentMethod,
    required String transactionId,
    String? mahalId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/payments/process'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'booking_id': bookingId,
          'amount': amount,
          'pay_method': paymentMethod,
          'pay_statement': transactionId,
          if (mahalId != null) 'mahal_id': mahalId,
        }),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      print('Error processing payment: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }
}
