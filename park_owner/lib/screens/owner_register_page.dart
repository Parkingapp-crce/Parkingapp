import 'package:flutter/material.dart';
import 'package:core/core.dart';
import '../services/api_service.dart';
import 'owner_login_page.dart';

class OwnerRegisterPage extends StatefulWidget {
  const OwnerRegisterPage({super.key});

  @override
  State<OwnerRegisterPage> createState() => _OwnerRegisterPageState();
}

class _OwnerRegisterPageState extends State<OwnerRegisterPage> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final flatCtrl = TextEditingController();
  final floorCtrl = TextEditingController();
  final joinCodeCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _register() async {
    if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty ||
        passwordCtrl.text.isEmpty || phoneCtrl.text.isEmpty ||
        flatCtrl.text.isEmpty || floorCtrl.text.isEmpty ||
        joinCodeCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final response = await ApiService.registerOwner(
        name: nameCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        flatNumber: flatCtrl.text.trim(),
        floorNumber: floorCtrl.text.trim(),
        joinCode: joinCodeCtrl.text.trim(),
      );

      if (response['message'] != null &&
          response['message'].toString().contains('success') || response['user'] != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Registration successful! Please login.'),
              backgroundColor: AppColors.success));
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const OwnerLoginPage()));
      } else {
        setState(() {
          _error = response['error'] ?? response.toString();
          _loading = false;
        });
      }
    } catch (e) {
      setState(() { _error = 'Connection error: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Registration',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ),
            _sectionLabel('Personal Info'),
            AppTextField(label: 'Full Name', hint: 'Enter full name', controller: nameCtrl),
            const SizedBox(height: 12),
            AppTextField(label: 'Email', hint: 'Enter email', controller: emailCtrl, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            AppTextField(label: 'Phone', hint: 'Enter phone number', controller: phoneCtrl, keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Password',
              hint: 'Enter password',
              controller: passwordCtrl,
              obscureText: _obscure,
              suffix: IconButton(
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: 24),
            _sectionLabel('Society Info'),
            AppTextField(label: 'Society Join Code', hint: 'Enter 6-digit code', controller: joinCodeCtrl),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: AppTextField(label: 'Flat Number', hint: 'e.g. A-101', controller: flatCtrl)),
                const SizedBox(width: 12),
                Expanded(child: AppTextField(label: 'Floor', hint: 'e.g. 1st', controller: floorCtrl)),
              ],
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Register as Owner',
              onPressed: _register,
              isLoading: _loading,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(label,
          style: TextStyle(color: AppColors.primary,
              fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
    );
  }
}
