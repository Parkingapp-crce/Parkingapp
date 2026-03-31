import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Note: Imports updated assuming this is now its own standalone project folder
import 'screens/admin_login_page.dart'; // Assuming a specific login/landing for admins
import 'screens/admin_dashboard.dart';

void main() {
  runApp(const ParkEasyAdminApp());
}

class ParkEasyAdminApp extends StatelessWidget {
  const ParkEasyAdminApp({super.key});

  Future<Widget> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final role = prefs.getString("role");

    // Strict check: Only allow access if the role is explicitly 'admin'
    if (token != null && role == 'admin') {
      return const AdminDashboard();
    }
    return const AdminLoginPage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ParkEasy - Admin',
      home: FutureBuilder<Widget>(
        future: checkLogin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF0A0A0A),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
              ),
            );
          }
          return snapshot.data ?? const AdminLoginPage();
        },
      ),
    );
  }
}