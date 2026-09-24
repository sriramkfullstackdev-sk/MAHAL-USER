import 'package:flutter/material.dart';
import '../screens/availability/availability_page.dart';
import '../screens/booking/booking_page.dart';
import '../screens/booking_form/booking_form_page.dart';
import '../screens/payment/payment_page.dart';
import '../screens/user_details/user_details_page.dart';
import '../screens/profile/profile_page.dart';
import '../screens/profile/edit_profile_page.dart';
import '../screens/profile/booking_history_page.dart';
import '../screens/otp/otp_page.dart';
import '../screens/verify_otp/verify_otp_page.dart';
import '../screens/home/home_page.dart';
import '../screens/visiting/select_visiting_time_page.dart';
import '../screens/visiting/qr_pass_page.dart';

class AppRoutes {
  static const String otpPage = "/otpPage";
  static const String verifyOtpPage = "/verifyOtpPage";
  static const String homePage = "/homePage";
  static const String bookingPage = "/bookingPage";
  static const String availabilityPage = "/availabilityPage";
  static const String bookingFormPage = "/bookingFormPage";
  static const String paymentPage = "/paymentPage";
  static const String userDetailsPage = "/userDetailsPage";
  static const String profilePage = "/profilePage";
  static const String editProfilePage = "/editProfilePage";
  static const String bookingHistoryPage = "/bookingHistoryPage";
  static const String selectVisitingTimePage = "/selectVisitingTimePage";
  static const String qrPassPage = "/qrPassPage";

  static Map<String, WidgetBuilder> routes = {
    otpPage: (context) => const OtpPage(),
    verifyOtpPage: (context) => const VerifyOtpPage(),
    homePage: (context) => const HomePage(),
    bookingPage: (context) => const BookingPage(),
    availabilityPage: (context) => const AvailabilityPage(),
    bookingFormPage: (context) => const BookingFormPage(),
    paymentPage: (context) => const PaymentPage(),
    userDetailsPage: (context) => const UserDetailsPage(),
    profilePage: (context) => const ProfilePage(),
    editProfilePage: (context) => const EditProfilePage(),
    bookingHistoryPage: (context) => const BookingHistoryPage(),
    selectVisitingTimePage: (context) => const SelectVisitingTimePage(),
    qrPassPage: (context) => const QrPassPage(),
  };
}
