// lib/screens/profile_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ghar_se_market/screens/login_screen.dart';
import 'package:ghar_se_market/services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _signOut(BuildContext context) async {
    final AuthService authService = AuthService();
    await authService.signOut();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- 1. डार्क मोड डिटेक्ट करें ---
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // --- 2. डायनामिक कलर्स ---
    final Color backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFF6F8FB);
    final Color glassColor = isDark ? Colors.black : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.grey.shade800;
    // ----------------------------

    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: backgroundColor, // डायनामिक बैकग्राउंड
      body: Stack(
        children: [
          // --- बैकग्राउंड ग्रेडिएंट (Dark/Light) ---
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                  Colors.blue.shade900.withOpacity(0.2),
                  const Color(0xFF121212),
                  Colors.purple.shade900.withOpacity(0.2),
                ]
                    : [
                  Colors.blue.shade100.withOpacity(0.4),
                  Colors.white,
                  Colors.purple.shade50.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // --- सजावटी ब्लब्स ---
          Positioned(
            top: -100,
            right: -50,
            child: _buildBlurBlob(Colors.blue.withOpacity(isDark ? 0.15 : 0.3)),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: _buildBlurBlob(Colors.purple.withOpacity(isDark ? 0.15 : 0.3)),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // --- हेडर (कलर्स पास करें) ---
                _buildGlassHeader(context, "Profile", glassColor, textColor),

                const SizedBox(height: 40),

                // --- प्रोफाइल कार्ड (कलर्स पास करें) ---
                _buildProfileCard(user, glassColor, textColor, isDark),

                const Spacer(),

                // --- साइन आउट बटन (कलर्स पास करें) ---
                Padding(
                  padding: const EdgeInsets.only(bottom: 50, left: 24, right: 24),
                  child: _buildSignOutButton(context, isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- प्रोफाइल कार्ड ---
  Widget _buildProfileCard(User? user, Color glassColor, Color textColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  glassColor.withOpacity(0.6),
                  glassColor.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: glassColor.withOpacity(isDark ? 0.3 : 0.6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // --- फोटो ---
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue.shade300, width: 2),
                    boxShadow: [
                      BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: user?.photoURL == null
                        ? Icon(Icons.person, size: 50, color: isDark ? Colors.white54 : Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),

                // --- नाम ---
                Text(
                  user?.displayName ?? "User Name",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // --- ईमेल ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.blue.withOpacity(0.2) : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user?.email ?? "No Email",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.blue.shade200 : Colors.blue.shade800,
                      fontWeight: FontWeight.w500,
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

  // --- साइन आउट बटन ---
  Widget _buildSignOutButton(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => _signOut(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.withOpacity(0.3), width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, color: isDark ? Colors.red.shade300 : Colors.red.shade700),
                const SizedBox(width: 12),
                Text(
                  "Sign Out",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- ग्लास हेडर ---
  Widget _buildGlassHeader(BuildContext context, String title, Color glassColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: glassColor.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: glassColor.withOpacity(0.5)),
                  ),
                  child: Icon(Icons.arrow_back, color: textColor),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildBlurBlob(Color color) {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 100,
            spreadRadius: 50,
          ),
        ],
      ),
    );
  }
}