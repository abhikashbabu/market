import 'dart:ui';
import 'package:flutter/material.dart';
import 'category_reminder_screen.dart'; // इसे हम अगले स्टेप में बनाएँगे

class SmartReminderScreen extends StatelessWidget {
  const SmartReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFF6F8FB);
    final Color textColor = isDark ? Colors.white : Colors.grey.shade900;
    final Color glassColor = isDark ? Colors.black : Colors.white;
    const Color themeColor = Colors.teal; // इस स्क्रीन के लिए Teal रंग

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // --- Header ---
            _buildGlassHeader(context, "Smart Reminders", glassColor, textColor),
            const SizedBox(height: 30),

            // --- Grid ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  children: [
                    _buildGridItem(context, "EMI / Bills", Icons.account_balance_wallet, Colors.orange, "EMI", glassColor, textColor),
                    _buildGridItem(context, "Time Table", Icons.schedule, Colors.blue, "TimeTable", glassColor, textColor),
                    _buildGridItem(context, "Medicine", Icons.medication, Colors.redAccent, "Medicine", glassColor, textColor),
                    _buildGridItem(context, "Subscription", Icons.subscriptions, Colors.purple, "Subscription", glassColor, textColor), // 4th Category
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, String title, IconData icon, Color color, String categoryKey, Color glassColor, Color textColor) {
    return GestureDetector(
      onTap: () {
        // उस कैटेगरी की लिस्ट खोलें
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryReminderScreen(category: categoryKey, themeColor: color),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: glassColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: glassColor.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassHeader(BuildContext context, String title, Color glassColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }
}