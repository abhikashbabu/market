import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart'; // 1. यह इम्पोर्ट करें
import '../database_helper.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final dbHelper = DatabaseHelper.instance;
  final LocalAuthentication auth = LocalAuthentication(); // बायोमेट्रिक ऑब्जेक्ट
  bool _isSecurityEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  // सिक्योरिटी सेटिंग्स लोड करें
  void _loadSecuritySettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSecurityEnabled = prefs.getBool('is_security_enabled') ?? false;
    });
  }

  // --- 1. सिक्योरिटी टॉगल लॉजिक ---
  void _toggleSecurity(bool value) async {
    final LocalAuthentication auth = LocalAuthentication();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (value) {
      // --- ON कर रहे हैं: पहले वेरीफाई करो कि यह असली मालिक है ---
      try {
        bool authenticated = await auth.authenticate(
          localizedReason: 'सिक्योरिटी ऑन करने के लिए वेरीफाई करें',
          options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
        );

        if (authenticated) {
          await prefs.setBool('is_security_enabled', true);
          setState(() {
            _isSecurityEnabled = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("App Lock Enabled!")));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: फ़ोन में लॉक सेट नहीं है?")));
      }
    } else {
      // --- OFF कर रहे हैं: फिर से वेरीफाई करो ---
      try {
        bool authenticated = await auth.authenticate(
          localizedReason: 'सिक्योरिटी हटाने के लिए वेरीफाई करें',
          options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
        );

        if (authenticated) {
          await prefs.setBool('is_security_enabled', false);
          setState(() {
            _isSecurityEnabled = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("App Lock Disabled")));
        }
      } catch (e) {
        print(e);
      }
    }
  }
  // --- 2. PIN सेट करने का डायलॉग (Create & Confirm) ---
  void _showSetPinDialog() {
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();

    // डार्क मोड चेक
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;

    showDialog(
      context: context,
      barrierDismissible: false, // बाहर क्लिक करने पर बंद न हो
      builder: (context) {
        return AlertDialog(
          backgroundColor: bgColor,
          title: Text("Set 4-Digit PIN", style: TextStyle(color: textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                style: TextStyle(color: textColor),
                decoration: const InputDecoration(labelText: "Enter PIN", counterText: ""),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmPinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                style: TextStyle(color: textColor),
                decoration: const InputDecoration(labelText: "Confirm PIN", counterText: ""),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (pinController.text.length == 4 && pinController.text == confirmPinController.text) {
                  // PIN सही है, सेव करें
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.setString('app_pin', pinController.text);
                  await prefs.setBool('is_security_enabled', true);

                  setState(() {
                    _isSecurityEnabled = true;
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Security Enabled!")));

                  // बायोमेट्रिक चेक करें
                  _checkBiometrics();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PINs do not match or invalid length")));
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // --- 3. बायोमेट्रिक और ऑथेंटिकेशन हेल्पर्स ---
  Future<void> _checkBiometrics() async {
    bool canCheckBiometrics = await auth.canCheckBiometrics;
    if (canCheckBiometrics) {
      // आप चाहें तो यहाँ पूछ सकते हैं "Enable Fingerprint too?"
      // अभी के लिए हम मान लेते हैं कि सिस्टम डिफॉल्ट बायोमेट्रिक यूज़ करेगा
    }
  }

  Future<bool> _authenticate() async {
    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to disable security',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // PIN भी चलेगा
        ),
      );
      return authenticated;
    } catch (e) {
      // अगर बायोमेट्रिक फेल हो, या उपलब्ध न हो, तो हम PIN मांग सकते हैं
      // (सिम्पलीसिटी के लिए अभी true रिटर्न नहीं कर रहे)
      print(e);
      return false;
    }
  }
  // --- 1. Export Data Logic ---
  void _exportData() async {
    try {
      // 1. डेटाबेस से डेटा लें
      final data = await dbHelper.getFullDatabase();

      // 2. JSON में बदलें
      String jsonString = jsonEncode(data);

      // 3. अस्थायी फ़ाइल बनाएँ
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/ghar_se_market_backup.json');
      await file.writeAsString(jsonString);

      // 4. शेयर करें (WhatsApp/Save/Email)
      await Share.shareXFiles([XFile(file.path)], text: 'My Shopping List Backup');

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- 2. Import Data Logic ---
  void _importData() async {
    try {
      // 1. फ़ाइल चुनें
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);

        // 2. फ़ाइल पढ़ें
        String jsonString = await file.readAsString();
        Map<String, dynamic> data = jsonDecode(jsonString);

        // 3. डेटाबेस में डालें
        await dbHelper.importDatabase(data);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Backup Restored Successfully!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error importing: $e")));
    }
  }

  // --- 3. Delete All Data Logic ---
  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Everything?"),
        content: const Text("सावधान! इससे आपकी सारी लिस्ट और आइटम डिलीट हो जाएंगे। यह वापस नहीं आएगा।"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await dbHelper.deleteAllData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All data deleted")));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("DELETE ALL", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- 4. Dark Mode Toggle ---
  void _toggleTheme(bool isDark) async {
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', isDark);
  }
  @override
  Widget build(BuildContext context) {
    bool isDarkMode = themeNotifier.value == ThemeMode.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(color: Theme.of(context).scaffoldBackgroundColor),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildHeader(context, "Settings"),
                const SizedBox(height: 20),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // --- Security Section (NEW) ---
                      _buildSectionHeader("Security"),
                      _buildGlassTile(
                        icon: Icons.security, // आइकन बदल दिया
                        title: "App Lock",
                        subtitle: "Use Phone's Screen Lock", // सबटाइटल बदला
                        color: Colors.green,
                        trailing: Switch(
                          value: _isSecurityEnabled,
                          onChanged: _toggleSecurity, // बस यह फंक्शन कॉल करें
                          activeColor: Colors.green,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // --- Appearance Section ---
                      _buildSectionHeader("Appearance"),
                      _buildGlassTile(
                        icon: isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        title: "Dark Mode",
                        trailing: Switch(
                          value: isDarkMode,
                          onChanged: _toggleTheme,
                          activeColor: Colors.blue,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // --- Data Management Section ---
                      _buildSectionHeader("Data Management"),
                      // ... (बाकी टाइल्स वैसे ही) ...
                      _buildGlassTile(
                        icon: Icons.upload_file,
                        title: "Export Data (Backup)",
                        subtitle: "Save your lists to a file",
                        onTap: _exportData,
                      ),

                      const SizedBox(height: 10),

                      _buildGlassTile(
                        icon: Icons.download_for_offline,
                        title: "Import Data (Restore)",
                        subtitle: "Restore from a backup file",
                        onTap: _importData,
                      ),

                      const SizedBox(height: 10),

                      _buildGlassTile(
                        icon: Icons.delete_forever,
                        title: "Clear All Data",
                        color: Colors.redAccent,
                        onTap: _confirmDeleteAll,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // --- UI Helpers ---

  Widget _buildGlassTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color color = Colors.blueGrey,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: ListTile(
            onTap: onTap,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
            trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}