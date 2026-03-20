import 'package:flutter/material.dart';
 import 'success_page.dart'; // Uncomment this to link to your Success Page

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // State for toggling password visibility
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Defining brand colors to match the design system
  final Color primaryGreen = const Color(0xFF1E7E34);
  final Color textDark = const Color(0xFF1B2236);
  final Color textGrey = const Color(0xFF6B7280);
  final Color fieldBackground = Colors.white;
  final Color borderColor = const Color(0xFFE5E7EB);
  final Color backgroundColor = const Color(0xFFF8F9FA); // Off-white app background
  final Color cardBackground = const Color(0xFFEEF5F0); // Light green background for the card
  final Color cardBorder = const Color(0xFFD5E8D4); // Soft border for the card

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Reset Password',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
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
                      // 1. Centered Top Icon
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: primaryGreen.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock_reset,
                            size: 40,
                            color: primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 2. Titles
                      Text(
                        'Create New Password',
                        style: TextStyle(
                          color: textDark,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Your new password must be different from previous used passwords.",
                        style: TextStyle(
                          color: textGrey,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 3. New Password Input
                      Text(
                        'New Password',
                        style: TextStyle(
                          color: textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPasswordField(
                        controller: newPasswordController,
                        hintText: 'Enter new password',
                        obscureText: _obscureNewPassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // 4. Confirm Password Input
                      Text(
                        'Confirm Password',
                        style: TextStyle(
                          color: textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPasswordField(
                        controller: confirmPasswordController,
                        hintText: 'Confirm your new password',
                        obscureText: _obscureConfirmPassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // 5. Password Requirements Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PASSWORD REQUIREMENTS',
                              style: TextStyle(
                                color: primaryGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Note: In a real app, these states would update dynamically based on the text input.
                            _buildRequirementRow(
                              text: 'At least 8 characters long',
                              isMet: true, // Hardcoded as true to match image
                            ),
                            const SizedBox(height: 8),
                            _buildRequirementRow(
                              text: 'Include one number and one symbol',
                              isMet: false, // Hardcoded as false to match image
                            ),
                          ],
                        ),
                      ),

                      // Spacer pushes the buttons to the bottom
                      const Spacer(),
                      const SizedBox(height: 24),

                      // 6. Reset Password Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Validation Logic
                            if (newPasswordController.text.isEmpty ||
                                confirmPasswordController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Fill all fields")),
                              );
                              return;
                            }

                            if (newPasswordController.text !=
                                confirmPasswordController.text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Passwords do not match")),
                              );
                              return;
                            }

                            // Navigate to Success Page
                            Navigator.push(
                               context,
                               MaterialPageRoute(
                                 builder: (context) => const SuccessPage(),
                               ),
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
                            'Reset Password',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 7. Cancel Button
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: textGrey,
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

  // Helper method to build text fields with visibility toggle
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
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

  // Helper method for the requirements list
  Widget _buildRequirementRow({required String text, required bool isMet}) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle_outline : Icons.radio_button_unchecked,
          color: isMet ? primaryGreen : textGrey.withOpacity(0.5),
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: textGrey,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}