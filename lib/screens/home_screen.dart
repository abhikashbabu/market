import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ghar_se_market/screens/my_lists_screen.dart';
import 'package:ghar_se_market/screens/password_screen.dart';
import 'package:ghar_se_market/screens/profile_screen.dart';
import 'package:ghar_se_market/screens/report_screen.dart';
import 'package:ghar_se_market/screens/settings_screen.dart'; // Settings Screen import करें
import 'package:ghar_se_market/screens/smart_reminder_screen.dart';
import 'package:ghar_se_market/screens/sync_service.dart';
import 'favorite_screen.dart';
import 'notes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();
    // --- ऐप खुलते ही क्लाउड से डेटा चेक करें ---
    _syncData();
  }

  void _syncData() async {
    // बैकग्राउंड में सिंक करें
    await SyncService().downloadFromCloud(context);
    setState(() {}); // सिंक होने के बाद UI रीफ्रेश करें
  }

  @override
  Widget build(BuildContext context) {
    // 1. चेक करें कि डार्क मोड ऑन है या नहीं
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // 2. डार्क मोड के हिसाब से रंग सेट करें
    final Color backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFF6F8FB);
    final Color textColor = isDark ? Colors.white : Colors.grey.shade900;
    final Color glassColor = isDark ? Colors.black : Colors.white; // ग्लास का बेस कलर

    final Color themeColor = const Color(0xFF2563EB);

    return Scaffold(
      extendBody: true,
      backgroundColor: backgroundColor, // डायनामिक बैकग्राउंड

      // ---------------------- BODY ----------------------
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 14),

            // ------------------ Floating Glass Logo ------------------
            _buildGlassHeaderLogo(themeColor, glassColor, textColor),

            const SizedBox(height: 20),

            // ------------------ Grid Section ------------------
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                  ),
                  children: [
                    _buildGlassGridItem(
                      context,
                      icon: Icons.list_alt,
                      label: "Market List",
                      color: themeColor,
                      glassColor: glassColor,
                      textColor: textColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyListsScreen(),
                          ),
                        );
                      },
                    ),

                    _buildGlassGridItem(
                      context,
                      icon: Icons.favorite_border,
                      label: "Favorite List",
                      color: Colors.pinkAccent,
                      glassColor: glassColor,
                      textColor: textColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const FavoriteScreen()),
                        );
                      },
                    ),
                    // --- New Password Manager Icon ---
                    _buildGlassGridItem(
                      context,
                      icon: Icons.lock_outline,
                      label: "Passwords",
                      color: Colors.deepPurple,
                      glassColor: glassColor,
                      textColor: textColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PasswordScreen()),
                        );
                      },
                    ),

                    _buildGlassGridItem(
                      context,
                      icon: Icons.bar_chart,
                      label: "Report",
                      color: Colors.green,
                      glassColor: glassColor,
                      textColor: textColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ReportScreen()),
                        );
                      },
                    ),
                    _buildGlassGridItem(
                      context,
                      icon: Icons.notifications_active_outlined, // या Icons.alarm
                      label: "Reminders",
                      color: Colors.teal,
                      glassColor: glassColor,
                      textColor: textColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SmartReminderScreen()),
                        );
                      },
                    ),
                    _buildGlassGridItem(
                      context,
                      icon: Icons.lightbulb_outline, // Keep का आइकन बल्ब जैसा होता है
                      label: "Notes",
                      color: Colors.amber,
                      glassColor: glassColor,
                      textColor: textColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotesScreen()),
                        );
                      },
                    ),

                    _buildGlassGridItem(
                      context,
                      icon: Icons.settings_outlined,
                      label: "Setting",
                      color: Colors.grey,
                      glassColor: glassColor,
                      textColor: textColor,
                      onTap: () {
                        // Settings Screen पर नेविगेट करें
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ----------------------- Floating Add Button -----------------------
      floatingActionButton: _buildGlassFloatingButton(themeColor),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ----------------------- Glass Bottom Nav -----------------------
      bottomNavigationBar: _buildGlassBottomNav(context, themeColor, glassColor, isDark),
    );
  }

  // ----------------------- Floating Glass Logo -----------------------
  Widget _buildGlassHeaderLogo(Color themeColor, Color glassColor, Color textColor) {
    return fakeGlass(
      radius: 20,
      glassColor: glassColor,
      opacity: 0.18,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    themeColor,
                    themeColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset("assets/icon/logo.png"),
            ),
            const SizedBox(width: 12),
            Text(
              "Yaado",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGlassGridItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required Color color,
        required Color glassColor,
        required Color textColor,
        required VoidCallback onTap,
      }) {

    return GestureDetector(
      onTap: onTap,
      child: fakeGlass(
        radius: 20,
        glassColor: glassColor,
        child: Container(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ICON CIRCLE
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.withOpacity(0.75),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.30),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(icon, size: 28, color: Colors.white),
              ),

              const SizedBox(height: 14),

              Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }


  // ----------------------- Floating Add Button -----------------------
  Widget _buildGlassFloatingButton(Color themeColor) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [themeColor, ColorDarken(themeColor).darken(0.12)],
        ),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // (नोट: यहाँ MyListsScreen पर ले जाने का लॉजिक जोड़ना अच्छा होगा)
        onPressed: () {},
        child: const Icon(
          Icons.add,
          size: 30,
          color: Colors.white,
        ),
      ),
    );
  }

  // ----------------------- Glass Bottom Navigation -----------------------
  Widget _buildGlassBottomNav(BuildContext context, Color themeColor, Color glassColor, bool isDark) {
    final iconColor = isDark ? Colors.white70 : Colors.grey.shade900.withOpacity(0.88);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 10, right: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  glassColor.withOpacity(0.30),
                  glassColor.withOpacity(0.12),
                  glassColor.withOpacity(0.06),
                ],
              ),
              border: Border.all(
                color: glassColor.withOpacity(0.45),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navIcon(Icons.home, iconColor, glassColor),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyListsScreen()),
                    );
                  },
                  child: _navIcon(Icons.list, iconColor, glassColor),
                ),

                const SizedBox(width: 40),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ReportScreen()),
                    );
                  },
                  child: _navIcon(Icons.receipt_long, iconColor, glassColor),
                ),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  },
                  child: _navIcon(Icons.person_outline, iconColor, glassColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navIcon(IconData icon, Color iconColor, Color glassColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            glassColor.withOpacity(0.40),
            glassColor.withOpacity(0.18),
          ],
        ),
      ),
      child: Icon(
        icon,
        size: 26,
        color: iconColor,
      ),
    );
  }
}
Widget fakeGlass({
  required Widget child,
  double radius = 18,
  double opacity = 0.15,
  double borderOpacity = 0.25,
  double shadowOpacity = 0.10,
  Color? glassColor,
}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: (glassColor ?? Colors.white).withOpacity(opacity),
      border: Border.all(
        color: (glassColor ?? Colors.white).withOpacity(borderOpacity),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(shadowOpacity),
          blurRadius: 20,
          offset: const Offset(0, 8),
        )
      ],
    ),
    child: child,
  );
}

// Helper Extension
extension ColorDarken on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}