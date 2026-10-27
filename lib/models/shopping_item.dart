// lib/models/shopping_item.dart
class ShoppingItem {
  final int? id;
  final String itemName;
  final double? quantity;
  final String? unit;
  final int listId; // <-- 1. यह नया फ़ील्ड जोड़ें
  final double estimatedPrice;
  final double marketPrice;
  final bool isPurchased;

  ShoppingItem({
    this.id,
    required this.itemName,
    required this.listId, // 2.
    this.quantity,
    this.unit,
    this.estimatedPrice = 0.0,
    this.marketPrice = 0.0,
    this.isPurchased = false,
  });

  // ShoppingItem को Map (डेटाबेस में सेव करने के लिए) में बदलें
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_name': itemName,
      'list_id': listId, // 3. 'list_id'
      'quantity': quantity,
      'unit': unit,
      'estimated_price': estimatedPrice,
      'market_price': marketPrice,
      'is_purchased': isPurchased ? 1 : 0, // SQL में bool को 0 या 1 की तरह सेव करते हैं
    };
  }

  // Map (डेटाबेस से) को ShoppingItem (ऐप में) में बदलें
  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id'],
      itemName: map['item_name'],
      quantity: map['quantity'],
      listId: map['list_id'],
      unit: map['unit'],
      estimatedPrice: map['estimated_price'],
      marketPrice: map['market_price'],
      isPurchased: map['is_purchased'] == 1,
    );
  }

  // टेस्टिंग के लिए
  @override
  String toString() {
    return 'ShoppingItem{id: $id, itemName: $itemName, quantity: $quantity, unit: $unit}';
  }
}