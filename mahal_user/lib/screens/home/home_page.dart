import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../widgets/user_app_bar.dart';
import '../../routes/app_routes.dart';

import 'widgets/search_bar_widget.dart';
import 'widgets/mahal_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: UserAppBar(
        title: 'Home',
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              SearchBarWidget(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 30),
              Expanded(child: MahalList(searchQuery: _searchController.text)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: AppColors.buttonEnd,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          if (index == 1) Navigator.pushReplacementNamed(context, AppRoutes.profilePage);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }
}
