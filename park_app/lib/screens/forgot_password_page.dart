import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'otp_page.dart';

class ForgotPasswordPage extends StatelessWidget {
  ForgotPasswordPage({super.key});

  final emailController = TextEditingController();

  final Color primaryGreen = const Color(0xFF1E7E34);
  final Color textDark = const Color(0xFF1B2236);
  final Color textGrey = const Color(0xFF6B7280);
  final Color fieldBackground = Colors.white;
  final Color borderColor = const Color(0xFFE5E7EB);
  final Color backgroundColor = const Color(0xFFF8F9FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
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
                        // Back Button
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back_ios_new, size: 18),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Icon
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E7E34).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(Icons.lock_reset, size: 45, color: primaryGreen),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Title
                        Text('Forgot Password',
                            style: TextStyle(color: textDark, fontSize: 28, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        Text(
                          "Enter your email address and we'll send you a 6-digit code to reset your password.",
                          style: TextStyle(color: textGrey, fontSize: 15, height: 1.5),
                        ),
                        const SizedBox(height: 32),

                        // Email field
                        Text('Email Address',
                            style: TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'example@email.com',
                            hintStyle: TextStyle(color: textGrey.withOpacity(0.6)),
                            prefixIcon: Icon(Icons.mail_outline, color: primaryGreen, size: 22),
                            filled: true,
                            fillColor: fieldBackground,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide(color: primaryGreen),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Send Reset Code Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final email = emailController.text.trim();

                              if (email.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Please enter your email")),
                                );
                                return;
                              }

                              try {
                                final res = await ApiService.forgotPassword(email);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(res["message"] ?? "Reset code sent!")),
                                );

                                // Always navigate to OTP page (don't reveal if email exists)
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OtpPage(email: email),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Server error. Please try again.")),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text('Send Reset Code',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),

                        const Spacer(),

                        // Footer
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              children: [
                                Text('Remember your password? ',
                                    style: TextStyle(color: textGrey, fontSize: 14)),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Text('Back to Login',
                                      style: TextStyle(
                                          color: primaryGreen, fontSize: 14, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
