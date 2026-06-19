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
    if (nameCtrl.text.isEmpty ||
        emailCtrl.text.isEmpty ||
        passwordCtrl.text.isEmpty ||
        phoneCtrl.text.isEmpty ||
        flatCtrl.text.isEmpty ||
        floorCtrl.text.isEmpty ||
        joinCodeCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
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
              response['message'].toString().contains('success') ||
          response['user'] != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please sign in.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OwnerLoginPage()),
        );
      } else {
        setState(() {
          _error = response['error'] ?? response.toString();
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Account',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Error banner ─────────────────────────────────────────────────
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontFamily: 'Inter'),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Personal info section ────────────────────────────────────────
            _SectionLabel(label: 'Personal Info'),
            AppTextField(
              label: 'Full Name',
              hint: 'Enter full name',
              controller: nameCtrl,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Email',
              hint: 'Enter email',
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Phone',
              hint: 'Enter phone number',
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Password',
              hint: 'Create a password',
              controller: passwordCtrl,
              obscureText: _obscure,
              suffix: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: 28),

            // ── Society info section ─────────────────────────────────────────
            _SectionLabel(label: 'Society Info'),
            AppTextField(
              label: 'Society Join Code',
              hint: 'Enter 6-digit code from your society admin',
              controller: joinCodeCtrl,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Flat Number',
                    hint: 'e.g. A-101',
                    controller: flatCtrl,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Floor',
                    hint: 'e.g. 1st',
                    controller: floorCtrl,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),

            PrimaryButton(
              label: 'Register as Resident',
              onPressed: _register,
              isLoading: _loading,
              icon: Icons.arrow_forward_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primaryLight,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}
