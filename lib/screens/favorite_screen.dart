import 'package:flutter/material.dart';
import 'package:ghar_se_market/screens/sync_service.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import '../models/shopping_list.dart';
import 'item_list_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final dbHelper = DatabaseHelper.instance;
  late Future<List<ShoppingList>> _favoriteLists;

  // फेवरेट स्क्रीन के लिए पिंक थीम
  final Color themeColor = Colors.pinkAccent;

  @override
  void initState() {
    super.initState();
    _loadFavoriteLists();
  }

  void _loadFavoriteLists() {
    setState(() {
      _favoriteLists = dbHelper.getFavoriteLists();
    });
  }

  void _toggleFavorite(ShoppingList list) async {
    // फेवरेट से हटाने का लॉजिक
    await dbHelper.toggleListFavorite(list.id!, !list.isFavorite);
    SyncService().uploadToCloud();
    _loadFavoriteLists(); // लिस्ट को रीफ्रेश करें

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("'${list.name}' removed from favorites"),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _deleteList(int id) async {
    await dbHelper.deleteList(id);
    SyncService().uploadToCloud();
    _loadFavoriteLists();
  }

  void _confirmDeleteList(ShoppingList list) {
    showDialog(
      context: context,
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Text("Delete List?", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          content: Text(
            "Are you sure you want to delete '${list.name}'?",
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteList(list.id!);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Delete", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. डार्क मोड डिटेक्ट करें
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // 2. डायनामिक कलर्स
    final Color backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFF6F8FB);
    final Color textColor = isDark ? Colors.white : Colors.grey.shade900;
    final Color glassColor = isDark ? Colors.white : Colors.white;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // --- बैकग्राउंड ब्लब्स ---
          Positioned(
            top: -100,
            right: -50,
            child: _buildBlurBlob(Colors.pink.withOpacity(0.15)),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: _buildBlurBlob(Colors.purple.withOpacity(0.15)),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 14),

                // --- हेडर (No Blur) ---
                _buildFastGlassHeaderTitle(themeColor, "Favorites", glassColor, textColor, isDark),

                const SizedBox(height: 20),

                Expanded(
                  child: FutureBuilder<List<ShoppingList>>(
                    future: _favoriteLists,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.favorite_border, size: 64, color: isDark ? Colors.white24 : Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                'No favorites yet.\nAdd from "My Lists".',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 18, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                              ),
                            ],
                          ),
                        );
                      }
                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          // --- कार्ड (No Blur) ---
                          return _buildFastGlassGridItem(snapshot.data![index], glassColor, textColor, isDark);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. Optimized Header ---
  Widget _buildFastGlassHeaderTitle(Color themeColor, String title, Color glassColor, Color textColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: isDark
                      ? [glassColor.withOpacity(0.12), glassColor.withOpacity(0.05)]
                      : [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
                    width: 1.2
                ),
              ),
              child: Icon(Icons.arrow_back, size: 22, color: textColor),
            ),
          ),

          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: isDark
                        ? [glassColor.withOpacity(0.12), glassColor.withOpacity(0.05)]
                        : [Colors.white.withOpacity(0.8), Colors.white.withOpacity(0.5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
                      width: 1.4
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
                ),
              ),
            ),
          ),
          const SizedBox(width: 46), // Balance space
        ],
      ),
    );
  }

  // --- 2. Optimized Grid Item ---
  Widget _buildFastGlassGridItem(ShoppingList list, Color glassColor, Color textColor, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ItemListScreen(list: list)),
        ).then((value) => _loadFavoriteLists());
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: isDark
                ? [glassColor.withOpacity(0.12), glassColor.withOpacity(0.05)]
                : [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
              width: 1.5
          ),
          boxShadow: [
            BoxShadow(
              color: themeColor.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
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
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.list_alt_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      list.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
                    ),
                  ),
                ],
              ),
            ),

            // --- Favorite Button (Filled Heart) ---
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _toggleFavorite(list),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.white.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded, // Always filled in this screen
                    size: 20,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ),

            // --- Delete Button ---
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap: () => _confirmDeleteList(list),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.white.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Colors.redAccent.shade200,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlurBlob(Color color) {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 100,
            spreadRadius: 50,
          ),
        ],
      ),
    );
  }
}

// Color Extension
extension ColorDarken on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}