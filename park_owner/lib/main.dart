import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'package:core/core.dart';
import 'screens/owner_login_page.dart';
import 'screens/owner_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeNotifier = await ThemeNotifier.create();
  if (!GetIt.I.isRegistered<ThemeNotifier>()) {
    GetIt.I.registerSingleton<ThemeNotifier>(themeNotifier);
  }
  runApp(ParkEasyOwnerApp(themeNotifier: themeNotifier));
}


class ParkEasyOwnerApp extends StatelessWidget {
  final ThemeNotifier themeNotifier;

  const ParkEasyOwnerApp({super.key, required this.themeNotifier});

  Future<Widget> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final role = prefs.getString("role");

    if (token != null && role == 'user') {
      return const OwnerDashboard();
    }
    return const OwnerLoginPage();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ParkEase - Owner',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeNotifier.themeMode,
        home: FutureBuilder<Widget>(
          future: checkLogin(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                ),
              );
            }
            return snapshot.data ?? const OwnerLoginPage();
          },
        ),
      ),
    );
  }
}
