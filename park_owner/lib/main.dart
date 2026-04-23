import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:core/core.dart';
// Note: Imports updated assuming this is now its own standalone project folder
import 'screens/owner_login_page.dart'; // Assuming you have a specific login/landing for owners
import 'screens/owner_dashboard.dart';

void main() {
  runApp(const ParkEasyOwnerApp());
}

class ParkEasyOwnerApp extends StatelessWidget {
  const ParkEasyOwnerApp({super.key});

  Future<Widget> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final role = prefs.getString("role");

    // Strict check: Only allow access if the role is explicitly 'user'
    if (token != null && role == 'user') {
      return const OwnerDashboard();
    }
    // If not logged in or wrong role, send to the owner's login/landing page
    return const OwnerLoginPage(); 
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ParkEasy - Owner',
      theme: AppTheme.light,
      home: FutureBuilder<Widget>(
        future: checkLogin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFFF8FAFC),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF2563EB)),
              ),
            );
          }
          return snapshot.data ?? const OwnerLoginPage();
        },
      ),
    );
  }
}