import 'package:flutter/material.dart';

class GlassInput extends StatelessWidget {

  final String hint;
  final IconData icon;
  final bool obscure;
  final TextEditingController controller;

  GlassInput({
    required this.hint,
    required this.icon,
    required this.controller,
    this.obscure = false
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}