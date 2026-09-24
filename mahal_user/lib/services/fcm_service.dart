import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../constants/api_constants.dart';
import 'auth_service.dart';

class FcmService {
  static const _tokenKey = 'fcm_token';

  static Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    await Firebase.initializeApp();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    FirebaseMessaging.onMessage.listen((message) {
      final context = navigatorKey.currentState?.overlay?.context;
      if (context == null) return;
      if (!context.mounted) return;

      final title = message.notification?.title ?? message.data['title']?.toString() ?? 'Booking Request Sent';
      final body = message.notification?.body ?? message.data['body']?.toString() ?? '';
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });

    final token = await messaging.getToken();
    await _saveToken(token);
    await registerToken(token);
    messaging.onTokenRefresh.listen((token) async {
      await _saveToken(token);
      await registerToken(token);
    });
  }

  static Future<void> _saveToken(String? token) async {
    if (token == null || token.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    debugPrint('FCM token: $token');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> registerToken(String? token) async {
    if (token == null || token.isEmpty) return;
    final jwt = await AuthService().getToken();
    if (jwt == null || jwt.isEmpty) return;

    await http.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/fcm-token'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
      body: jsonEncode({'fcm_token': token}),
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}