import 'package:flutter/material.dart';

class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key});

  // Defining brand colors to match the design
  final Color primaryGreen = const Color(0xFF1E7E34);
  final Color textDark = const Color(0xFF1B2236);
  final Color textGrey = const Color(0xFF6B7280);
  final Color cardBackground = const Color(0xFFEEF5F0); // Light green background for the card
  final Color cardBorder = const Color(0xFFD5E8D4); // Soft border for the card
  final Color backgroundColor = const Color(0xFFF8F9FA); // Off-white app background

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
          'ParkEasy',
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
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      // 1. Success Icon with glowing background effect
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryGreen.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // 2. Headings
                      Text(
                        'Password Updated!',
                        style: TextStyle(
                          color: textDark,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your password has been successfully\nreset. You can now log in with your new\npassword.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textGrey,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // 3. Security Verification Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder, width: 1),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.lock_outline,
                                color: primaryGreen,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'SECURITY VERIFICATION PASSED',
                              style: TextStyle(
                                color: primaryGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // 4. Back to Login Button
                      ElevatedButton(
                        onPressed: () {
                          // Clears the stack and goes back to the first route (Login)
                          Navigator.popUntil(context, (route) => route.isFirst);
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
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Back to Login',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.login, size: 20),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 5. Contact Support Text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Need help? ',
                            style: TextStyle(color: textGrey, fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () {
                              // Handle support navigation
                            },
                            child: Text(
                              'Contact Support',
                              style: TextStyle(
                                color: primaryGreen,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const Spacer(),

                      // 6. Bottom Decorative Element
                      Container(
                        height: 120,
                        width: 250,
                        decoration: const BoxDecoration(
                          color: Color(0xFFC4C4C4), // Placeholder grey
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(30),
                          ),
                        ),
                        // You can replace this container's color with a decoration image 
                        // if you have the actual graphic asset for the bottom shapes.
                      ),
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
}