// lib/screens/my_lists_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ghar_se_market/widgets/fake_glass.dart';
import 'package:ghar_se_market/screens/sync_service.dart';
import '../database_helper.dart';
import '../models/shopping_list.dart';
import 'item_list_screen.dart';

class MyListsScreen extends StatefulWidget {
  const MyListsScreen({super.key});

  @override
  State<MyListsScreen> createState() => _MyListsScreenState();
}

class _MyListsScreenState extends State<MyListsScreen> {
  final dbHelper = DatabaseHelper.instance;
  late Future<List<ShoppingList>> _lists;
  final TextEditingController _listNameController = TextEditingController();

  final Color themeColor = const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  void _loadLists() {
    setState(() {
      _lists = dbHelper.getAllLists();
    });
  }

  void _toggleFavorite(ShoppingList list) async {
    await dbHelper.toggleListFavorite(list.id!, !list.isFavorite);
    SyncService().uploadToCloud();
    _loadLists();
  }

  void _deleteList(int id) async {
    await dbHelper.deleteList(id);
    SyncService().uploadToCloud();
    _loadLists();
  }

  void _confirmDeleteList(ShoppingList list) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("लिस्ट हटाएँ"),
        content: Text("क्या आप सचमुच '${list.name}' को हटाना चाहते हैं?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("नहीं")),
          ElevatedButton(
            onPressed: () {
              _deleteList(list.id!);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("हाँ", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color backgroundColor =
    isDark ? const Color(0xFF121212) : const Color(0xFFF6F8FB);

    final Color textColor =
    isDark ? Colors.white : Colors.grey.shade900;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 14),

            /// -------- Header --------
            _header(textColor, isDark),

            const SizedBox(height: 16),

            /// -------- LIST GRID --------
            Expanded(
              child: FutureBuilder<List<ShoppingList>>(
                future: _lists,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        'कोई लिस्ट नहीं है।\n+ दबाकर नई लिस्ट बनाएँ।',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: isDark ? Colors.white54 : Colors.grey.shade700,
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return _listCard(snapshot.data![index], textColor, isDark);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: _fab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// -------- Header (Fake Glass) --------
  Widget _header(Color textColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: fakeGlass(
        radius: 22,
        opacity: isDark ? 0.10 : 0.65,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              /// Back
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                  child: Icon(Icons.arrow_back, color: textColor),
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: Text(
                  "Market Lists",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),

              const SizedBox(width: 38),
            ],
          ),
        ),
      ),
    );
  }

  /// -------- EACH CARD (Fake Glass) --------
  Widget _listCard(ShoppingList list, Color textColor, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ItemListScreen(list: list)),
        ).then((value) => _loadLists());
      },
      child: fakeGlass(
        radius: 20,
        opacity: isDark ? 0.10 : 0.60,
        child: Stack(
          children: [
            /// Center content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [themeColor, themeColor.withOpacity(0.75)],
                      ),
                    ),
                    child: const Icon(Icons.list_alt_rounded,
                        size: 28, color: Colors.white),
                  ),

                  const SizedBox(height: 14),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      list.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// Favorite
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => _toggleFavorite(list),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.white12 : Colors.white.withOpacity(0.5),
                  ),
                  child: Icon(
                    list.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: list.isFavorite ? Colors.red : textColor,
                    size: 20,
                  ),
                ),
              ),
            ),

            /// Delete
            Positioned(
              top: 10,
              left: 10,
              child: GestureDetector(
                onTap: () => _confirmDeleteList(list),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.white12 : Colors.white.withOpacity(0.5),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// -------- Add FAB --------
  Widget _fab() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [themeColor, themeColor.withOpacity(0.75)],
        ),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: _showCreateListDialog,
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
    );
  }

  // Create List Dialog
  void _showCreateListDialog() {
    _listNameController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("नई लिस्ट बनाएँ"),
        content: TextField(
          controller: _listNameController,
          decoration: const InputDecoration(hintText: "जैसे: Monthly Grocery"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (_listNameController.text.isNotEmpty) {
                await dbHelper.createNewList(
                  ShoppingList(name: _listNameController.text),
                );
                SyncService().uploadToCloud();
                _loadLists();
                Navigator.pop(context);
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }
}

Widget fakeGlass({
  required Widget child,
  double radius = 18,
  double opacity = 0.18,
  double borderOpacity = 0.30,
  Color color = Colors.white,
}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: color.withOpacity(opacity),
      border: Border.all(
        color: color.withOpacity(borderOpacity),
        width: 1.4,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 18,
          offset: const Offset(0, 6),
        )
      ],
    ),
    child: child,
  );
}
