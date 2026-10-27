import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    try {
      setState(() => _isAuthenticating = true);

      bool authenticated = await auth.authenticate(
        localizedReason: 'Unlock to continue',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      setState(() => _isAuthenticating = false);

      if (authenticated && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on PlatformException catch (e) {
      print(e);
      setState(() => _isAuthenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color themeColor = const Color(0xFF2563EB);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ------------------- GLASS BACKGROUND -------------------
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade100.withOpacity(0.45),
                  Colors.white.withOpacity(0.90),
                  Colors.blue.shade50.withOpacity(0.30),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Soft Glow Circle
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxShapeDecoration(
                shape: BoxShape.circle,
                color: themeColor.withOpacity(0.25),
              ),
            ),
          ),

          // ------------------- MAIN CONTENT -------------------
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ---------- Floating Glass Lock Icon ----------
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.38),
                            Colors.white.withOpacity(0.18),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.45),
                          width: 1.4,
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
                        width: 95,
                        height: 95,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              themeColor,
                              themeColor.withOpacity(0.8),
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
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ---------- Glass Title ----------
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.35),
                            Colors.white.withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.40),
                          width: 1.3,
                        ),
                      ),
                      child: Text(
                        "App Locked",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade900,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Text(
                  "Authenticate to continue",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 40),

                // ---------- GLASS UNLOCK BUTTON ----------
                if (!_isAuthenticating)
                  GestureDetector(
                    onTap: _authenticate,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.45),
                                Colors.white.withOpacity(0.22),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.45),
                              width: 1.3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.10),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.fingerprint,
                                  size: 26, color: themeColor),
                              const SizedBox(width: 12),
                              Text(
                                "Unlock App",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade900,
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

/// Helps to create circular glowing bg
class BoxShapeDecoration extends Decoration {
  final Color color;
  final BoxShape shape;

  const BoxShapeDecoration({required this.color, this.shape = BoxShape.circle});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _BoxShapePainter(color: color);
}

class _BoxShapePainter extends BoxPainter {
  final Color color;

  _BoxShapePainter({required this.color});

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration config) {
    final Paint paint = Paint()..color = color;
    canvas.drawCircle(
        offset + Offset(config.size!.width / 2, config.size!.height / 2),
        config.size!.width / 2,
        paint);
  }
}
