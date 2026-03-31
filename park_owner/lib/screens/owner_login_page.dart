import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'owner_dashboard.dart';
import '../screens/owner_register_page.dart';

class OwnerLoginPage extends StatefulWidget {
  const OwnerLoginPage({super.key});

  @override
  State<OwnerLoginPage> createState() => _OwnerLoginPageState();
}

class _OwnerLoginPageState extends State<OwnerLoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await ApiService.loginUser(
          emailController.text.trim(), passwordController.text.trim());

      if (response['tokens'] != null) {
        final role = response['user']?['role'] ?? 'customer';
        if (role != 'owner') {
          setState(() { _error = 'This account is not an owner account.'; _loading = false; });
          return;
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', response['tokens']['access']);
        await prefs.setString('role', 'owner');
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const OwnerDashboard()),
            (route) => false);
      } else {
        setState(() { _error = response['error'] ?? 'Login failed'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Connection error'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF7C4DFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.3)),
              ),
              child: const Icon(Icons.business_rounded, color: Color(0xFF7C4DFF), size: 26),
            ),
            const SizedBox(height: 20),
            const Text('Owner Login',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800,
                    color: Colors.white, letterSpacing: -1)),
            const SizedBox(height: 8),
            Text('Manage your parking lot',
                style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.4))),
            const SizedBox(height: 40),
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),
            _buildField('Email', emailController, false),
            const SizedBox(height: 16),
            _buildField('Password', passwordController, _obscure, isPassword: true),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C4DFF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Login', style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Don't have an account? ",
                    style: TextStyle(color: Colors.white.withOpacity(0.4))),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const OwnerRegisterPage())),
                  child: const Text('Register',
                      style: TextStyle(color: Color(0xFF7C4DFF), fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, bool obscure,
      {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5),
            fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF141414),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF7C4DFF))),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white38),
                    onPressed: () => setState(() => _obscure = !_obscure))
                : null,
          ),
        ),
      ],
    );
  }
}
