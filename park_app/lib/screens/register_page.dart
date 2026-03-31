import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool hidePassword = true;
  bool agree = false;
  bool _isLoading = false; // Added loading state

  final Color primaryGreen = const Color(0xFF1E7E34);
  final Color textGrey = const Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text("Create Account"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            /// 🔹 TOP IMAGE
            Image.asset(
              "assets/images/car.png",
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// Title
                  const Text(
                    "Join ParkEasy",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "Start your journey with us today and access thousands of cars.",
                    style: TextStyle(color: textGrey),
                  ),

                  const SizedBox(height: 20),

                  /// Name
                  _buildField("Full Name", nameController, Icons.person),

                  const SizedBox(height: 15),

                  /// Email
                  _buildField("Email Address", emailController, Icons.email),

                  const SizedBox(height: 15),

                  /// Password
                  _buildPasswordField("Password", passwordController),

                  const SizedBox(height: 15),

                  /// Confirm Password
                  _buildPasswordField("Confirm Password", confirmPasswordController),

                  const SizedBox(height: 15),

                  /// Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: agree,
                        onChanged: (value) {
                          setState(() {
                            agree = value!;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          "I agree to the Terms of Service and Privacy Policy.",
                          style: TextStyle(color: textGrey, fontSize: 12),
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// Register Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      // Disable button if loading
                      onPressed: _isLoading ? null : () async {

                        final name = nameController.text.trim();
                        final email = emailController.text.trim();
                        final password = passwordController.text.trim();
                        final confirm = confirmPasswordController.text.trim();

                        if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
                          _show("Fill all fields");
                          return;
                        }

                        if (password != confirm) {
                          _show("Passwords do not match");
                          return;
                        }

                        if (!agree) {
                          _show("Please accept terms");
                          return;
                        }

                        // Start loading
                        setState(() {
                          _isLoading = true;
                        });

                        try {
                          final res = await ApiService.registerUser(name, email, password);

                          // CRITICAL: Check if the widget is still mounted after the async call
                          if (!mounted) return;

                          // ✅ FIX: Django returns "User registered successfully." (with dot)
                          if (res["message"] == "User registered successfully.") {
                            _show("Registered Successfully!");
                            // Pop back to the login page
                            Navigator.pop(context);
                          } else {
                            // Show actual error from Django
                            final error = res["email"]?[0] ??
                                res["message"] ??
                                "Registration failed";
                            _show(error);
                          }
                        } catch (e) {
                          if (!mounted) return;
                          _show("Server error. Please try again.");
                          print("REGISTER ERROR: $e");
                        } finally {
                          // Stop loading whether it succeeded or failed
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        // Adjust disabled color if you like
                        disabledBackgroundColor: primaryGreen.withOpacity(0.6),
                      ),
                      child: _isLoading 
                          ? const SizedBox(
                              height: 20, 
                              width: 20, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text("Create Account", style: TextStyle(color: Colors.white)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Social
                  const Center(child: Text("or continue with")),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(child: _socialBtn("Google", "assets/images/Google.svg")),
                      const SizedBox(width: 10),
                      Expanded(child: _socialBtn("Apple", "assets/images/Apple.svg")),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// Back to login
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "Already have an account? ",
                          style: TextStyle(color: textGrey),
                          children: [
                            TextSpan(
                              text: "Sign In",
                              style: TextStyle(
                                color: primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildField(String hint, controller, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPasswordField(String hint, controller) {
    return TextField(
      controller: controller,
      obscureText: hidePassword,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(hidePassword ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              hidePassword = !hidePassword;
            });
          },
        ),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _socialBtn(String text, String svgPath) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(svgPath, height: 20),
          const SizedBox(width: 10),
          Text(text),
        ],
      ),
    );
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}