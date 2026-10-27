// lib/models/shopping_list.dart
class ShoppingList {
  final int? id;
  final String name;
  final String? color;
  final DateTime? createdAt;
  final bool isFavorite; // <-- 1. यह नई लाइन जोड़ें

  ShoppingList({
    this.id,
    required this.name,
    this.color,
    this.createdAt,
    this.isFavorite = false, // <-- 2. इसे कंस्ट्रक्टर में जोड़ें (डिफ़ॉल्ट false)
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      // 'created_at' को यहाँ सेव करने की ज़रूरत नहीं, डेटाबेस खुद मैनेज करेगा
      'is_favorite': isFavorite ? 1 : 0, // <-- 3. इसे toMap में जोड़ें
    };
  }

  factory ShoppingList.fromMap(Map<String, dynamic> map) {
    return ShoppingList(
      id: map['id'],
      name: map['name'],
      color: map['color'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      isFavorite: map['is_favorite'] == 1, // <-- 4. इसे fromMap में पढ़ें
    );
  }
}