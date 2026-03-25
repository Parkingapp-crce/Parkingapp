import 'package:flutter/material.dart';
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
  final lotNameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final slotsCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final openingCtrl = TextEditingController();
  final closingCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _register() async {
    if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty ||
        passwordCtrl.text.isEmpty || lotNameCtrl.text.isEmpty ||
        addressCtrl.text.isEmpty || cityCtrl.text.isEmpty ||
        slotsCtrl.text.isEmpty || priceCtrl.text.isEmpty ||
        openingCtrl.text.isEmpty || closingCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final response = await ApiService.registerOwner(
        name: nameCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
        lotName: lotNameCtrl.text.trim(),
        address: addressCtrl.text.trim(),
        city: cityCtrl.text.trim(),
        totalSlots: int.tryParse(slotsCtrl.text.trim()) ?? 0,
        pricePerHour: double.tryParse(priceCtrl.text.trim()) ?? 0,
        openingTime: openingCtrl.text.trim(),
        closingTime: closingCtrl.text.trim(),
      );

      if (response['message'] != null &&
          response['message'].toString().contains('success')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please login.'),
              backgroundColor: Color(0xFF7C4DFF)));
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const OwnerLoginPage()));
      } else {
        setState(() {
          _error = response['error'] ?? response.toString();
          _loading = false;
        });
      }
    } catch (e) {
      setState(() { _error = 'Connection error'; _loading = false; });
    }
  }

  Future<void> _pickTime(TextEditingController ctrl) async {
    final picked = await showTimePicker(
        context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      ctrl.text = '$h:$m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Owner Registration',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),
            _sectionLabel('Personal Info'),
            _buildField('Full Name', nameCtrl),
            const SizedBox(height: 12),
            _buildField('Email', emailCtrl),
            const SizedBox(height: 12),
            _buildField('Password', passwordCtrl, obscure: _obscure, isPassword: true),
            const SizedBox(height: 24),
            _sectionLabel('Parking Lot Info'),
            _buildField('Parking Lot Name', lotNameCtrl),
            const SizedBox(height: 12),
            _buildField('Address', addressCtrl),
            const SizedBox(height: 12),
            _buildField('City', cityCtrl),
            const SizedBox(height: 12),
            _buildField('Total Number of Slots', slotsCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _buildField('Price per Hour (₹)', priceCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTimePicker('Opening Time', openingCtrl)),
                const SizedBox(width: 12),
                Expanded(child: _buildTimePicker('Closing Time', closingCtrl)),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C4DFF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Register as Owner',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                            color: Colors.white)),
              ),
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
          style: TextStyle(color: const Color(0xFF7C4DFF).withOpacity(0.9),
              fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {bool obscure = false, bool isPassword = false,
      TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5),
            fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF141414),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF7C4DFF))),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white38),
                    onPressed: () => setState(() => _obscure = !_obscure))
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5),
            fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _pickTime(ctrl),
          child: AbsorbPointer(
            child: TextField(
              controller: ctrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF141414),
                hintText: '00:00',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                suffixIcon: Icon(Icons.access_time_rounded,
                    color: Colors.white.withOpacity(0.3), size: 18),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF7C4DFF))),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
