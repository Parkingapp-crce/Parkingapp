import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:core/core.dart';
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.loginUser(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (response['access'] != null || response['tokens'] != null) {
        final access = response['access'] ?? response['tokens']['access'];
        final role = response['user']?['role'] ?? 'user';
        if (role != 'user') {
          setState(() {
            _error = 'This account is not a resident account.';
            _loading = false;
          });
          return;
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', access);
        await prefs.setString('role', 'user');
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const OwnerDashboard()),
          (route) => false,
        );
      } else {
        setState(() {
          _error = response['error'] ?? 'Login failed';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Brand capsule ────────────────────────────────────────────
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'PARKWISE · RESIDENT',
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Headline ─────────────────────────────────────────────────
                Text(
                  'Welcome back.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to manage your parking slots.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 15,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 36),

                // ── Error banner ─────────────────────────────────────────────
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
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

                // ── Fields ───────────────────────────────────────────────────
                AppTextField(
                  controller: emailController,
                  label: 'Email',
                  hint: 'Enter your email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  prefixIcon: Icons.lock_outlined,
                  obscureText: _obscure,
                  suffix: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Sign in button ───────────────────────────────────────────
                PrimaryButton(
                  label: 'Sign In',
                  onPressed: _login,
                  isLoading: _loading,
                  icon: Icons.arrow_forward_rounded,
                ),
                const SizedBox(height: 20),

                // ── Register link ────────────────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const OwnerRegisterPage()),
                    ),
                    child: RichText(
                      text: TextSpan(
                        text: 'New resident? ',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          fontFamily: 'Inter',
                        ),
                        children: const [
                          TextSpan(
                            text: 'Create account',
                            style: TextStyle(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
