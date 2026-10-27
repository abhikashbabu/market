// lib/screens/language_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'login_screen.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  void _setLanguage(BuildContext context, String langCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', langCode);
    MyApp.setLocale(context, Locale(langCode));

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color themeColor = const Color(0xFF2563EB);

    // --- 1. डार्क मोड डिटेक्ट करें ---
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // --- 2. डायनामिक कलर्स ---
    final Color backgroundColor = isDark ? const Color(0xFF121212) : Colors.white;
    final Color glassColor = isDark ? Colors.black : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.grey.shade900;
    // ----------------------------

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: backgroundColor,

      body: Stack(
        children: [

          // ---------------- BACKGROUND LIGHTING ----------------
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                  Colors.blue.shade900.withOpacity(0.3),
                  const Color(0xFF121212),
                  Colors.blue.shade900.withOpacity(0.2),
                ]
                    : [
                  Colors.blue.shade200.withOpacity(0.35),
                  Colors.white,
                  Colors.blue.shade50.withOpacity(0.25),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Radial glow
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 330,
              height: 330,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.blue.withOpacity(0.15)
                    : Colors.blue.shade100.withOpacity(0.30),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.blue.withOpacity(0.2)
                        : Colors.blue.shade300.withOpacity(0.35),
                    blurRadius: 140,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          // ---------------- MAIN CONTENT ----------------
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // --------- GLASS TITLE ---------
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            glassColor.withOpacity(0.32),
                            glassColor.withOpacity(0.14),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: glassColor.withOpacity(0.50),
                          width: 1.3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Text(
                        "Choose Language / भाषा चुनें",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // --------- ENGLISH BUTTON ---------
                _glassButton(
                  label: "English",
                  icon: Icons.language,
                  onTap: () => _setLanguage(context, 'en'),
                  themeColor: themeColor,
                  glassColor: glassColor,
                  textColor: textColor,
                ),

                const SizedBox(height: 28),

                // --------- HINDI BUTTON ---------
                _glassButton(
                  label: "हिंदी",
                  icon: Icons.translate_rounded,
                  onTap: () => _setLanguage(context, 'hi'),
                  themeColor: Colors.deepOrange,
                  glassColor: glassColor,
                  textColor: textColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- GLASS BUTTON COMPONENT ----------
  Widget _glassButton({
    required String label,
    required IconData icon,
    required Function onTap,
    required Color themeColor,
    required Color glassColor,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: () => onTap(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  glassColor.withOpacity(0.50),
                  glassColor.withOpacity(0.20),
                ],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: glassColor.withOpacity(0.55),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: themeColor.withOpacity(0.30),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: themeColor,
                  size: 26,
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}