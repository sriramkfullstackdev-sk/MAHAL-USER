import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mahal_model.dart';
import '../constants/api_constants.dart';

class MahalService {
  Future<List<MahalModel>> getAllMahals() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/mahals'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List mahals = data['data'];
          return mahals.map((m) => MahalModel.fromJson(m)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching mahals: $e');
      return [];
    }
  }
}
