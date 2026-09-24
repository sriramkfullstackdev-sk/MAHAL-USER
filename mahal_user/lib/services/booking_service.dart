import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class BookingService {
  Future<Map<String, dynamic>> getBookingHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/bookings/history'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(response.body);
      return response.statusCode == 200
          ? data
          : {'success': false, 'message': data['message'] ?? 'Unable to load bookings'};
    } catch (e) {
      debugPrint('Error fetching booking history: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  Future<Map<String, dynamic>> getDefaultTimings(String mahalId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/mahals/$mahalId/default-timings'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Failed to load default timings'};
    } catch (e) {
      debugPrint('Error fetching default timings: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  Future<Map<String, dynamic>> createBooking({
    required String mahalId,
    required String bookingDate,
    required String endDate,
    required String eventName,
    required String bookingType,
    required String eventTime,
    required String endTime,
    required String totalAmt,
    required String initialAmt,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'mahal_id': mahalId,
          'booking_date': bookingDate,
          'end_date': endDate,
          'event_name': eventName,
          'booking_type': bookingType,
          'event_time': eventTime,
          'end_time': endTime,
          'total_amt': totalAmt,
          'initial_amt': initialAmt,
        }),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      debugPrint('Error creating booking: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  Future<Map<String, dynamic>> checkDateAvailability(String mahalId, String bookingDate) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/bookings/availability?mahal_id=$mahalId&booking_date=$bookingDate'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Failed to check date availability'};
    } catch (e) {
      debugPrint('Error checking date availability: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }
}
