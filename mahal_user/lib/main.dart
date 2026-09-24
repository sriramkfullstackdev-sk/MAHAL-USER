import 'package:flutter/material.dart';
import 'services/fcm_service.dart';
import 'services/auth_service.dart';
import 'routes/app_routes.dart';
import 'utils/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final navigatorKey = GlobalKey<NavigatorState>();
  final hasSession = await AuthService().hasSession();
  await FcmService.initialize(navigatorKey);
  runApp(MyApp(hasSession: hasSession, navigatorKey: navigatorKey));
}

class MyApp extends StatelessWidget {
  final bool hasSession;
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({super.key, this.hasSession = false, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.buttonEnd),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.buttonEnd,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.buttonEnd,
            side: const BorderSide(color: AppColors.buttonEnd),
          ),
        ),
      ),
      initialRoute: hasSession ? AppRoutes.homePage : AppRoutes.otpPage,
      routes: AppRoutes.routes,
    );
  }
}