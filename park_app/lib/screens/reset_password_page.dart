import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'success_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final Color primaryGreen = const Color(0xFF1E7E34);
  final Color textDark = const Color(0xFF1B2236);
  final Color textGrey = const Color(0xFF6B7280);
  final Color fieldBackground = Colors.white;
  final Color borderColor = const Color(0xFFE5E7EB);
  final Color backgroundColor = const Color(0xFFF8F9FA);
  final Color cardBackground = const Color(0xFFEEF5F0);
  final Color cardBorder = const Color(0xFFD5E8D4);

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _hasMinLength => newPasswordController.text.length >= 8;
  bool get _hasNumberOrSymbol =>
      newPasswordController.text.contains(RegExp(r'[0-9!@#$%^&*(),.?":{}|<>]'));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Reset Password',
            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: primaryGreen.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.lock_reset, size: 40, color: primaryGreen),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Title
                      Text('Create New Password',
                          style: TextStyle(color: textDark, fontSize: 24, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(
                        "Your new password must be different from previously used passwords.",
                        style: TextStyle(color: textGrey, fontSize: 14, height: 1.5),
                      ),
                      const SizedBox(height: 32),

                      // New Password
                      Text('New Password',
                          style: TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      _buildPasswordField(
                        controller: newPasswordController,
                        hintText: 'Enter new password',
                        obscureText: _obscureNewPassword,
                        onToggleVisibility: () {
                          setState(() => _obscureNewPassword = !_obscureNewPassword);
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 20),

                      // Confirm Password
                      Text('Confirm Password',
                          style: TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      _buildPasswordField(
                        controller: confirmPasswordController,
                        hintText: 'Confirm your new password',
                        obscureText: _obscureConfirmPassword,
                        onToggleVisibility: () {
                          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                        },
                      ),
                      const SizedBox(height: 24),

                      // Requirements card (live)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PASSWORD REQUIREMENTS',
                                style: TextStyle(
                                    color: primaryGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0)),
                            const SizedBox(height: 12),
                            _buildRequirementRow('At least 8 characters long', _hasMinLength),
                            const SizedBox(height: 8),
                            _buildRequirementRow('Include one number or symbol', _hasNumberOrSymbol),
                          ],
                        ),
                      ),

                      const Spacer(),
                      const SizedBox(height: 24),

                      // Reset Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () async {
                            if (newPasswordController.text.isEmpty ||
                                confirmPasswordController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Fill all fields")),
                              );
                              return;
                            }

                            if (newPasswordController.text != confirmPasswordController.text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Passwords do not match")),
                              );
                              return;
                            }

                            if (newPasswordController.text.length < 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Password must be at least 6 characters")),
                              );
                              return;
                            }

                            setState(() => _isLoading = true);

                            try {
                              final res = await ApiService.resetPassword(
                                widget.email,
                                newPasswordController.text,
                              );

                              if (res["message"] == "Password reset successfully.") {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SuccessPage()),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(res["error"] ?? "Reset failed.")),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Server error. Please try again.")),
                              );
                            } finally {
                              setState(() => _isLoading = false);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Reset Password',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Cancel
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel',
                              style: TextStyle(
                                  color: textGrey, fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: textGrey.withOpacity(0.6)),
        filled: true,
        fillColor: fieldBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: primaryGreen),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: textGrey,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle_outline : Icons.radio_button_unchecked,
          color: isMet ? primaryGreen : textGrey.withOpacity(0.5),
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: textGrey, fontSize: 13)),
      ],
    );
  }
}
