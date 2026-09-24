import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/user_app_bar.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final AuthService _authService = AuthService();
  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _addressController;
  bool _isSaving = false;
  bool _initialized = false;
  String? _profileImagePath;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final profile = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    _nameController = TextEditingController(text: profile['name']?.toString() ?? '');
    _mobileController = TextEditingController(text: profile['mbl_no']?.toString() ?? '');
    _addressController = TextEditingController(text: profile['address']?.toString() ?? '');
    _profileImagePath = profile['profile_image_path']?.toString();
    _loadProfileImage();
    _initialized = true;
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted || _profileImagePath != null) return;
    setState(() => _profileImagePath = prefs.getString('profile_image_path'));
  }

  Future<void> _pickProfileImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;
    setState(() => _profileImagePath = image.path);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_path', image.path);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final mobileNumber = _mobileController.text.trim();
    final address = _addressController.text.trim();
    if (name.isEmpty || mobileNumber.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all profile fields')));
      return;
    }

    setState(() => _isSaving = true);
    final result = await _authService.updateProfile(
      name: name,
      mobileNumber: mobileNumber,
      address: address,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result['success'] == true) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Unable to update profile')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const UserAppBar(title: 'Edit Profile', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickProfileImage,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.accent,
                    backgroundImage: _profileImagePath == null ? null : FileImage(File(_profileImagePath!)),
                    child: _profileImagePath == null ? const Icon(Icons.person, color: Colors.white, size: 48) : null,
                  ),
                  Positioned(
                    right: -2,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: AppColors.primaryEnd, shape: BoxShape.circle),
                      child: const Icon(Icons.edit, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          _ProfileField(label: 'Name', controller: _nameController),
          const SizedBox(height: 18),
          _ProfileField(label: 'Mobile number', controller: _mobileController, keyboardType: TextInputType.phone),
          const SizedBox(height: 18),
          _ProfileField(label: 'Address', controller: _addressController, maxLines: 4),
          const SizedBox(height: 30),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryEnd,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int maxLines;

  const _ProfileField({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primaryEnd)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
