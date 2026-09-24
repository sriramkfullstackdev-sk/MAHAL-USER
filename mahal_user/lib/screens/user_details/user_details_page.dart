import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../widgets/user_app_bar.dart';
import 'widgets/custom_textfield.dart';
import 'widgets/location_field.dart';
import 'widgets/state_dropdown.dart';
import 'widgets/terms_checkbox.dart';
import 'widgets/finish_button.dart';

class UserDetailsPage extends StatefulWidget {
  const UserDetailsPage({super.key});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _address1Controller = TextEditingController(); // Flat, House No...
  final TextEditingController _address2Controller = TextEditingController(); // Door No
  final TextEditingController _address3Controller = TextEditingController(); // Area, Street
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  
  String? selectedState;
  bool isChecked = true;
  bool _isLoading = false;

  final List<String> states = [
    "Tamil Nadu",
    "Kerala",
    "Karnataka",
    "Andhra Pradesh",
  ];

  bool _initialized = false;
  String _mobileNumber = '';
  bool _userExists = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        _mobileNumber = args['mobileNumber'] ?? '';
        _userExists = args['userExists'] ?? false;
        final user = args['user'];
        if (user != null) {
          _nameController.text = user['name'] ?? '';
          
          final address = user['address'] ?? '';
          if (address.isNotEmpty) {
            // Very simple address split assuming the format we save
            final parts = address.split(', Door No: ');
            if (parts.length > 1) {
              _address1Controller.text = parts[0];
              final rest = parts[1].split(', ');
              if (rest.length > 1) {
                _address2Controller.text = rest[0];
                _address3Controller.text = rest[1];
                if (rest.length > 2) {
                  final cityPin = rest[2].split(' - ');
                  if (cityPin.length > 1) {
                    _cityController.text = cityPin[0];
                    _pincodeController.text = cityPin[1];
                  } else {
                    _cityController.text = rest[2];
                  }
                }
              }
            } else {
              _address1Controller.text = address;
            }
          }
          selectedState = user['state'];
        }
      } else if (args is String) {
        _mobileNumber = args;
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _address3Controller.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _handleRegister(String mobileNumber) async {
    if (!isChecked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please accept Terms & Conditions")));
      return;
    }
    
    if (_userExists) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.homePage, (r) => false);
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your name")));
      return;
    }

    final address = "${_address1Controller.text}, Door No: ${_address2Controller.text}, ${_address3Controller.text}, ${_cityController.text} - ${_pincodeController.text}";

    setState(() => _isLoading = true);
    
    // Call the auth service to register
    final authService = AuthService();
    final result = await authService.registerUser(
      mobileNumber: mobileNumber,
      name: name,
      address: address,
      state: selectedState ?? 'Tamil Nadu',
    );
    
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // Navigate to Home Page on success
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.homePage, (r) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Registration failed')));
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const UserAppBar(title: 'Profile', showBack: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text("USER DETAILS", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(height: 35),
              CustomTextField(hintText: "User name", controller: _nameController),
              const SizedBox(height: 18),
              CustomTextField(hintText: "mobile number", controller: TextEditingController(text: _mobileNumber)),
              const SizedBox(height: 18),
              const LocationField(),
              const SizedBox(height: 20),
              const Text("Address", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              const Text("Flat ,House no ,Building,Company,Apartment", style: TextStyle(fontSize: 14)),
              const SizedBox(height: 10),
              CustomTextField(controller: _address1Controller),
              const SizedBox(height: 15),
              const Text("Door no :", style: TextStyle(fontSize: 14)),
              const SizedBox(height: 10),
              CustomTextField(controller: _address2Controller),
              const SizedBox(height: 15),
              const Text("Area,Street,Sector,Village", style: TextStyle(fontSize: 14)),
              const SizedBox(height: 10),
              CustomTextField(controller: _address3Controller),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Pincode", style: TextStyle(fontSize: 14)),
                        const SizedBox(height: 10),
                        CustomTextField(controller: _pincodeController),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Town/city", style: TextStyle(fontSize: 14)),
                        const SizedBox(height: 10),
                        CustomTextField(controller: _cityController),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              StateDropdown(
                value: selectedState,
                items: states,
                onChanged: (value) {
                  setState(() {
                    selectedState = value;
                  });
                },
              ),
              const SizedBox(height: 30),
              TermsCheckbox(
                value: isChecked,
                onChanged: (value) {
                  setState(() {
                    isChecked = value!;
                  });
                },
              ),
              const SizedBox(height: 35),
              Center(
                child: _isLoading 
                  ? const CircularProgressIndicator()
                  : FinishButton(
                      text: _userExists ? 'Login' : 'Submit',
                      onTap: () => _handleRegister(_mobileNumber),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

