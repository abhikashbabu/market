// lib/services/sync_service.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../database_helper.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // --- 1. डेटा क्लाउड पर भेजो (Upload/Backup) ---
  // जब भी आप कुछ सेव/एडिट/डिलीट करें, इसे कॉल करें
  Future<void> uploadToCloud() async {
    final user = _auth.currentUser;
    if (user == null) return; // अगर लॉगिन नहीं है तो कुछ न करें

    try {
      // 1. लोकल डेटाबेस से सारा डेटा निकालें (JSON फॉर्मेट में)
      final data = await _dbHelper.getFullDatabase();
      String jsonString = jsonEncode(data);

      // 2. Firestore में यूज़र की ID के अंदर सेव करें
      await _firestore.collection('users').doc(user.uid).set({
        'backup_data': jsonString,
        'last_updated': FieldValue.serverTimestamp(),
        'email': user.email,
      });

      print("☁️ Cloud Backup Successful for ${user.email}");
    } catch (e) {
      print("⚠️ Cloud Upload Failed: $e");
    }
  }

  // --- 2. क्लाउड से डेटा लाओ (Download/Restore) ---
  // जब ऐप खुले या लॉगिन हो, इसे कॉल करें
  Future<void> downloadFromCloud(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // 1. Firestore से डेटा माँगें
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;

        if (data.containsKey('backup_data')) {
          String jsonString = data['backup_data'];
          Map<String, dynamic> dbData = jsonDecode(jsonString);

          // 2. लोकल डेटाबेस में डालें (पुराना हटाकर नया डालें)
          // ध्यान दें: यह लोकल डेटा को क्लाउड वाले डेटा से बदल देगा
          await _dbHelper.deleteAllData(); // पहले सफाई
          await _dbHelper.importDatabase(dbData); // फिर नया डेटा

          print("📥 Cloud Restore Successful");

          // UI को बताने के लिए कि डेटा आ गया है (स्नैकबार दिखा सकते हैं)
          // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data synced from Cloud!")));
        }
      }
    } catch (e) {
      print("⚠️ Cloud Download Failed: $e");
    }
  }
}