import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import '../services/notification_service.dart';

class CategoryReminderScreen extends StatefulWidget {
  final String category;
  final Color themeColor;

  const CategoryReminderScreen({super.key, required this.category, required this.themeColor});

  @override
  State<CategoryReminderScreen> createState() => _CategoryReminderScreenState();
}

class _CategoryReminderScreenState extends State<CategoryReminderScreen> {
  final dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _reminders = [];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  void _loadReminders() async {
    final data = await dbHelper.getRemindersByCategory(widget.category);
    setState(() {
      _reminders = data;
    });
  }

  void _addReminder() async {
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {

            // डार्क मोड चेक
            final bool isDark = Theme.of(context).brightness == Brightness.dark;
            final Color textColor = isDark ? Colors.white : Colors.black;

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              title: Text("Add ${widget.category} Reminder", style: TextStyle(color: textColor)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: "Title (e.g. Car Loan)",
                      labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Date Picker
                  ListTile(
                    title: Text("Date: ${DateFormat('dd MMM yyyy').format(selectedDate)}", style: TextStyle(color: textColor)),
                    trailing: Icon(Icons.calendar_today, color: widget.themeColor),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setDialogState(() => selectedDate = date);
                      }
                    },
                  ),

                  // Time Picker
                  ListTile(
                    title: Text("Time: ${selectedTime.format(context)}", style: TextStyle(color: textColor)),
                    trailing: Icon(Icons.access_time, color: widget.themeColor),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (time != null) {
                        setDialogState(() => selectedTime = time);
                      }
                    },
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
                    if (titleController.text.isNotEmpty) {
                      try {
                        // फाइनल डेट-टाइम बनाएँ
                        final scheduleTime = DateTime(
                          selectedDate.year, selectedDate.month, selectedDate.day,
                          selectedTime.hour, selectedTime.minute,
                        );

                        // --- 1. समय चेक करें ---
                        if (scheduleTime.isBefore(DateTime.now())) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a future time")));
                          return;
                        }

                        print("Saving to DB...");

                        // --- 2. डेटाबेस में डालें ---
                        int id = await dbHelper.insertReminder({
                          'title': titleController.text,
                          'category': widget.category,
                          'remind_time': scheduleTime.toIso8601String(),
                          'is_active': 1
                        });

                        print("Saved to DB with ID: $id");

                        // --- 3. नोटिफिकेशन शेड्यूल करें ---
                        await NotificationService().scheduleNotification(
                            id,
                            "Reminder: ${widget.category}",
                            titleController.text,
                            scheduleTime
                        );

                        print("Notification Scheduled");

                        Navigator.pop(context);
                        _loadReminders();

                      } catch (e) {
                        // --- ERROR यहाँ दिखेगा ---
                        print("ERROR SAVING REMINDER: $e");
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a title")));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: widget.themeColor),
                  child: const Text("Save", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _delete(int id) async {
    await dbHelper.deleteReminder(id);
    NotificationService().cancelNotification(id); // अलार्म भी बंद करें
    _loadReminders();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        backgroundColor: widget.themeColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF6F8FB),
      body: _reminders.isEmpty
          ? Center(child: Text("No reminders yet", style: TextStyle(color: isDark ? Colors.white : Colors.black)))
          : ListView.builder(
        itemCount: _reminders.length,
        itemBuilder: (context, index) {
          final item = _reminders[index];
          final date = DateTime.parse(item['remind_time']);
          return Card(
            color: isDark ? Colors.grey[900] : Colors.white,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: widget.themeColor.withOpacity(0.2), child: Icon(Icons.alarm, color: widget.themeColor)),
              title: Text(item['title'], style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
              subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(date), style: TextStyle(color: isDark ? Colors.white70 : Colors.grey)),
              trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(item['id'])),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminder,
        backgroundColor: widget.themeColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}