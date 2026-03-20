import 'package:flutter/material.dart';
import 'reset_password_page.dart';  //Uncomment this when you have the target page ready

class ForgotPasswordPage extends StatelessWidget {
  ForgotPasswordPage({super.key});

  final emailController = TextEditingController();

  // Defining brand colors to match the design system
  final Color primaryGreen = const Color(0xFF1E7E34);
  final Color textDark = const Color(0xFF1B2236);
  final Color textGrey = const Color(0xFF6B7280);
  final Color fieldBackground = Colors.white; 
  final Color borderColor = const Color(0xFFE5E7EB);
  final Color backgroundColor = const Color(0xFFF8F9FA); // Off-white app background

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Circular Back Button
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new, 
                              size: 18, 
                              color: Colors.black
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // 2. Centered Top Icon
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: primaryGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.lock_reset, // Standard material icon for reset
                              size: 45,
                              color: primaryGreen,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // 3. Titles
                        Text(
                          'Forgot Password',
                          style: TextStyle(
                            color: textDark,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Enter your email address and we'll send you instructions to reset your password.",
                          style: TextStyle(
                            color: textGrey,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // 4. Email Input Field
                        Text(
                          'Email Address',
                          style: TextStyle(
                            color: textDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

                        // 5. Send Reset Link Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                              context,
                               MaterialPageRoute(builder: (context) => ResetPasswordPage()),
                               );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Send Reset Link',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        
                        // Spacer pushes the footer to the bottom of the screen
                        const Spacer(),

                        // 6. Footer Layout
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Remember your password? ',
                                  style: TextStyle(color: textGrey, fontSize: 14),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    'Back to Login',
                                    style: TextStyle(
                                      color: primaryGreen,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
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