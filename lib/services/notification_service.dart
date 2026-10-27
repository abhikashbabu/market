// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    // --- 1. (FIX) भारत का टाइमज़ोन सेट करें ---
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (e) {
      print("Timezone Error: $e");
      // अगर 'Asia/Kolkata' न मिले तो डिफ़ॉल्ट UTC ही रहेगा
    }
    // ----------------------------------------

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("Notification Clicked: ${response.payload}");
      },
    );

    // --- 2. (FIX) परमिशन मांगें (Android 13+) ---
    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();
  }

  Future<void> scheduleNotification(int id, String title, String body, DateTime scheduledTime) async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        // --- 3. (FIX) सही टाइमज़ोन के साथ समय ---
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'My Reminders',
            channelDescription: 'Notifications for tasks',
            importance: Importance.max,
            priority: Priority.high,
            // आवाज़ और वाइब्रेशन सुनिश्चित करें
            playSound: true,
            enableVibration: true,
          ),
        ),
        // "Inexact" मोड ताकि बैटरी सेवर इसे न रोके
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      print("✅ Alarm Scheduled for: $scheduledTime");
    } catch (e) {
      print("❌ Error Scheduling Notification: $e");
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
