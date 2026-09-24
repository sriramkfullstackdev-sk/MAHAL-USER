import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../widgets/user_app_bar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();

  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isLoggingOut = false;
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadProfile();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _profileImagePath = prefs.getString('profile_image_path'));
  }

  Future<void> _loadProfile() async {
    final profileResult = await _authService.getProfile();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (profileResult['success'] == true) {
        _profile = Map<String, dynamic>.from(profileResult['data'] ?? {});
      }
    });
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.otpPage, (route) => false);
  }

  String _value(dynamic value, [String fallback = 'Not available']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  @override
  Widget build(BuildContext context) {
    final name = _value(_profile?['name'], 'User');
    final mobile = _value(_profile?['mbl_no'], 'Mobile number unavailable');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const UserAppBar(title: 'Profile', showBack: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [
                  _ProfileHeader(
                    name: name,
                    mobile: mobile,
                    imagePath: _profileImagePath,
                    onTap: () async {
                      final updated = await Navigator.pushNamed(context, AppRoutes.editProfilePage, arguments: _profile);
                      if (updated == true) _loadProfile();
                    },
                  ),
                  const SizedBox(height: 28),
                  _ProfileMenuTile(
                    icon: Icons.calendar_month_outlined,
                    title: 'My Bookings',
                    subtitle: 'View all your mahal bookings',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.bookingHistoryPage),
                  ),
                  const SizedBox(height: 28),
                  OutlinedButton.icon(
                    onPressed: _isLoggingOut ? null : _logout,
                    icon: _isLoggingOut
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepOrange,
                      side: const BorderSide(color: Colors.deepOrange),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: AppColors.primaryEnd,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, AppRoutes.homePage);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String mobile;
  final String? imagePath;
  final VoidCallback onTap;

  const _ProfileHeader({required this.name, required this.mobile, required this.onTap, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: AppColors.subtleShadow, blurRadius: 12, offset: Offset(0, 5))],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.accent,
              backgroundImage: imagePath == null ? null : FileImage(File(imagePath!)),
              child: imagePath == null ? const Icon(Icons.person, color: Colors.white, size: 34) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 5),
                  Text(mobile, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 5),
                  const Text('Tap to edit profile', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
