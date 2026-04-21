import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/qr_scanner_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ParkGuardApp());
}

class ParkGuardApp extends StatelessWidget {
  const ParkGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ParkWise Guard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E7E34)),
        useMaterial3: true,
        fontFamily: 'SF Pro Display', // falls back to system font
      ),
      home: const AuthGate(),
    );
  }
}

// ─── Decides whether to show Login or Scanner ───
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  bool _isLoggedIn = false;
  String _guardName = '';

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');
    final name = prefs.getString('guard_name') ?? '';

    // Only let guards in
    if (token != null && role == 'guard') {
      setState(() {
        _isLoggedIn = true;
        _guardName = name;
      });
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E7E34),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_isLoggedIn) {
      return GuardScannerPage(guardName: _guardName);
    }

    return const LoginScreen();
  }
}