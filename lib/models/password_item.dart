// lib/models/shopping_list.dart (नहीं, नई फाइल बनाएँ) -> password_item.dart

class PasswordItem {
  final int? id;
  final String title; // (जैसे: Facebook, Gmail)
  final String email;
  final String password;

  PasswordItem({
    this.id,
    required this.title,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'email': email,
      'password': password,
    };
  }

  factory PasswordItem.fromMap(Map<String, dynamic> map) {
    return PasswordItem(
      id: map['id'],
      title: map['title'],
      email: map['email'],
      password: map['password'],
    );
  }
}