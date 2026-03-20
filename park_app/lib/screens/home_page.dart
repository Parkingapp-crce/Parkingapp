import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color primaryGreen = const Color(0xFF1E7E34);
  final Color textDark = const Color(0xFF1B2236);
  final Color textGrey = const Color(0xFF6B7280);

  String? userEmail;
  String? userName;

  /// 🔥 Dynamic parking data
  String selectedParking = "Grand Central Park";
  double selectedPrice = 6.0;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  /// ✅ FETCH PROFILE FROM BACKEND
  Future<void> fetchProfile() async {
    try {
      final data = await ApiService.getProfile();

      setState(() {
        userEmail = data["user"]?["email"];
        userName = data["user"]?["name"];
      });
    } catch (e) {
      print("ERROR: $e");
    }
  }

  /// ✅ LOGOUT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  String getName() {
    if (userName != null) return userName!;
    if (userEmail == null) return "Driver";
    return userEmail!.split("@")[0];
  }

  @override
  Widget build(BuildContext context) {
    /// 🔄 Loading state
    if (userEmail == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,

      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: primaryGreen,
        unselectedItemColor: textGrey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Bookings"),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Wallet"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),

      body: Stack(
        children: [
          /// 🌄 Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFDECD1),
                  Color(0xFFE8F3E5),
                  Color(0xFFB1CDB3),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          /// 📍 CLICKABLE MARKERS
          Positioned(
            top: 250,
            left: 100,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedParking = "Street Parking";
                  selectedPrice = 4.0;
                });
              },
              child: _mapMarker("\$4/hr"),
            ),
          ),

          Positioned(
            top: 380,
            left: MediaQuery.of(context).size.width / 2 - 40,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedParking = "Grand Central Park";
                  selectedPrice = 6.0;
                });
              },
              child: _mapMarker("\$6/hr", isActive: true),
            ),
          ),

          /// 🔝 TOP UI
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  /// HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Welcome, ${getName()} 👋",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: logout,
                      )
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// SEARCH
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Find parking...",
                      prefixIcon: Icon(Icons.search, color: primaryGreen),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// 📦 BOTTOM CARD (DYNAMIC)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    color: Colors.black12,
                    child: const Icon(Icons.local_parking),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedParking,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "\$${selectedPrice.toStringAsFixed(2)}/hr",
                          style: TextStyle(color: primaryGreen),
                        ),
                      ],
                    ),
                  ),

                  ElevatedButton(
                    onPressed: () {},
                    child: const Text("Book"),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _mapMarker(String label, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive ? primaryGreen : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}