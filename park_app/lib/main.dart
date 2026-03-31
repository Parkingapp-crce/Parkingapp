import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/landing_page.dart';
import 'screens/home_page.dart';

void main() {
  runApp(const ParkEasyCustomerApp());
}

class ParkEasyCustomerApp extends StatelessWidget {
  const ParkEasyCustomerApp({super.key});

  Future<Widget> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final role = prefs.getString("role");

    // Depending on your backend, you might explicitly check if role == 'customer'
    if (token != null && (role == 'customer' || role == null)) {
      return const HomePage();
    }
    return const LandingPage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ParkEasy',
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
          return snapshot.data ?? const LandingPage();
        },
      ),
    );
  }
}