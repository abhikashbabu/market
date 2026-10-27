import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ghar_se_market/screens/auth_screen.dart';
import 'package:ghar_se_market/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ghar_se_market/l10n/app_localizations.dart';

import 'package:ghar_se_market/screens/home_screen.dart';
import 'screens/language_screen.dart';

// --- 1. (नया) थीम कंट्रोलर ---
// यह पूरे ऐप को बताएगा कि थीम कब बदलनी है
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Firebase must be ready before FirebaseAuth is used by MyApp. Keep a
    // timeout so a broken Firebase configuration cannot leave the native
    // splash screen visible forever.
    await Firebase.initializeApp().timeout(const Duration(seconds: 15));
  } catch (error, stackTrace) {
    debugPrint('Firebase startup failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    runApp(StartupErrorApp(error: error));
    return;
  }

  runApp(const MyApp());

  // Notification permission requests must happen after the first Flutter
  // frame. Awaiting Android 13+ permission before runApp can keep the app on
  // the native splash/black screen until the permission dialog is answered.
  unawaited(_initializeNotifications());
}

Future<void> _initializeNotifications() async {
  try {
    await NotificationService().init();
  } catch (error, stackTrace) {
    // Notifications are optional at startup; they must not prevent the app
    // UI from opening.
    debugPrint('Notification startup failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // भाषा बदलने का ग्लोबल फंक्शन
  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool? isDark = prefs.getBool('isDarkMode');
      if (isDark != null) {
        themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
      }

      final String? langCode = prefs.getString('language');
      if (langCode != null && mounted) {
        setLocale(Locale(langCode));
      }
    } catch (error, stackTrace) {
      debugPrint('Preferences startup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- 3. (नया) ValueListenableBuilder जोड़ें ---
    // यह थीम बदलने पर ऐप को रीबिल्ड करेगा
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Yaado',

          // --- 4. (नया) थीम सेटिंग्स ---
          themeMode: currentMode,

          // लाइट थीम (Light Theme)
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF6F8FB),
            cardColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),

          // डार्क थीम (Dark Theme)
          darkTheme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
            ),
          ),
          // ---------------------------

          locale: _locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('hi'), // Hindi
          ],

          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (snapshot.hasData) {
                // --- नया लॉजिक: सिक्योरिटी चेक ---
                return FutureBuilder<bool>(
                  future: _checkSecurityEnabled(),
                  builder: (context, securitySnapshot) {
                    if (securitySnapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(body: Center(child: CircularProgressIndicator()));
                    }
                    // अगर सिक्योरिटी ON है, तो AuthScreen, नहीं तो HomeScreen
                    if (securitySnapshot.data == true) {
                      return const AuthScreen();
                    }
                    return const HomeScreen();
                  },
                );
                // -----------------------------
              }

              return const LanguageScreen(); // या LoginScreen
            },
          ),

        );
      },

    );
  }
  Future<bool> _checkSecurityEnabled() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_security_enabled') ?? false;
  }
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({required this.error, super.key});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'App start nahi ho paaya',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(error.toString(), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
