// lib/screens/login_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ghar_se_market/screens/home_screen.dart';
import 'package:ghar_se_market/services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final Color themeColor = const Color(0xFF2563EB);

    // --- 1. डार्क मोड डिटेक्ट करें ---
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // --- 2. डायनामिक कलर्स ---
    final Color backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FB);
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
                  Colors.blue.shade900.withOpacity(0.25),
                  const Color(0xFF121212),
                  Colors.blue.shade900.withOpacity(0.15),
                ]
                    : [
                  Colors.blue.shade100.withOpacity(0.35),
                  Colors.white,
                  Colors.blue.shade50.withOpacity(0.25),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Soft radial glow
          Positioned(
            top: -80,
            left: -40,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.blue.withOpacity(0.15)
                    : Colors.blue.shade200.withOpacity(0.25),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.blue.withOpacity(0.2)
                        : Colors.blue.shade300.withOpacity(0.35),
                    blurRadius: 120,
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

                // ----------- GLASS LOGO WITH SOFT GLOW -----------
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            glassColor.withOpacity(0.40),
                            glassColor.withOpacity(0.18),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: glassColor.withOpacity(0.50),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: themeColor.withOpacity(0.20),
                            blurRadius: 40,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              themeColor,
                              themeColor.withOpacity(0.80),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: themeColor.withOpacity(0.55),
                              blurRadius: 28,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Image.asset("assets/icon/logo.png"),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                // ---------------- GLASS TITLE CAPSULE ----------------
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            glassColor.withOpacity(0.35),
                            glassColor.withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: glassColor.withOpacity(0.45),
                          width: 1.3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Text(
                        "Yaado",
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // ---------------- GOOGLE SIGN-IN GLASS BUTTON ----------------
                GestureDetector(
                  onTap: () async {
                    var user = await authService.signInWithGoogle();

                    if (user != null && context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                      );
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              glassColor.withOpacity(0.50),
                              glassColor.withOpacity(0.22),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: glassColor.withOpacity(0.45),
                            width: 1.3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 25,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset("assets/google.png", height: 26),
                            const SizedBox(width: 14),
                            Text(
                              "Sign in with Google",
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}