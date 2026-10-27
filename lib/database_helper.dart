import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'models/note_model.dart';
import 'models/password_item.dart';
import 'models/shopping_item.dart';
import 'models/shopping_list.dart'; // 1. इसे हम अगले स्टेप में बनाएंगे

class DatabaseHelper {
  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), 'marketlist_v2.db'); // v2
    return await openDatabase(path,
        version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    // टेबल 1: Lists (सही सिंटेक्स के साथ)
    await db.execute('''
    CREATE TABLE Lists (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      color TEXT,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP, -- यहाँ कॉमा ज़रूरी है
      is_favorite INTEGER DEFAULT 0
    )
    ''');

    // टेबल 2: ListItems
    await db.execute('''
    CREATE TABLE ListItems (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      list_id INTEGER NOT NULL,
      item_name TEXT NOT NULL,
      quantity REAL,
      unit TEXT,
      estimated_price REAL DEFAULT 0.0,
      market_price REAL DEFAULT 0.0,
      is_purchased INTEGER DEFAULT 0,
      FOREIGN KEY (list_id) REFERENCES Lists (id) ON DELETE CASCADE 
    )
    ''');
    await db.execute('''
    CREATE TABLE Passwords (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT,
      email TEXT NOT NULL,
      password TEXT NOT NULL
    )
    ''');
    await db.execute('''
    CREATE TABLE Reminders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      category TEXT NOT NULL, -- (EMI, Medicine, TimeTable, Subscription)
      remind_time TEXT NOT NULL, -- (ISO String format)
      is_active INTEGER DEFAULT 1
    )
    ''');
    await db.execute('''
    CREATE TABLE Notes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT,
      content TEXT,
      date TEXT,
      color_index INTEGER
    )
    ''');
  }
  Future<int> insertNote(Note note) async {
    Database db = await instance.database;
    return await db.insert('Notes', note.toMap());
  }

  Future<List<Note>> getNotes() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('Notes', orderBy: 'id DESC');
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  Future<int> updateNote(Note note) async {
    Database db = await instance.database;
    return await db.update('Notes', note.toMap(), where: 'id = ?', whereArgs: [note.id]);
  }

  Future<int> deleteNote(int id) async {
    Database db = await instance.database;
    return await db.delete('Notes', where: 'id = ?', whereArgs: [id]);
  }
  Future<int> insertReminder(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('Reminders', row);
  }

  Future<List<Map<String, dynamic>>> getRemindersByCategory(String category) async {
    Database db = await instance.database;
    return await db.query('Reminders', where: 'category = ?', whereArgs: [category], orderBy: 'remind_time ASC');
  }

  Future<int> deleteReminder(int id) async {
    Database db = await instance.database;
    return await db.delete('Reminders', where: 'id = ?', whereArgs: [id]);
  }
  // ---------- 4. Lists के लिए फंक्शन्स ----------
  Future<int> insertPassword(PasswordItem item) async {
    Database db = await instance.database;
    return await db.insert('Passwords', item.toMap());
  }

  Future<List<PasswordItem>> getAllPasswords() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('Passwords', orderBy: 'id DESC');
    return List.generate(maps.length, (i) {
      return PasswordItem.fromMap(maps[i]);
    });
  }

  Future<int> deletePassword(int id) async {
    Database db = await instance.database;
    return await db.delete('Passwords', where: 'id = ?', whereArgs: [id]);
  }
  // नई "Keep" लिस्ट बनाना
  Future<int> createNewList(ShoppingList list) async {
    Database db = await instance.database;
    return await db.insert('Lists', list.toMap());
  }
  Future<void> deleteAllData() async {
    Database db = await instance.database;
    await db.delete('ListItems'); // पहले आइटम हटाएँ
    await db.delete('Lists');     // फिर लिस्ट हटाएँ
  }
  Future<List<ShoppingList>> getAllLists(
      {DateTime? startDate, DateTime? endDate}) async {
    Database db = await instance.database;

    String? whereClause;
    List<dynamic>? whereArgs;

    if (startDate != null && endDate != null) {
      // दोनों तारीखों के बीच
      whereClause = 'DATE(created_at) BETWEEN DATE(?) AND DATE(?)';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    } else if (startDate != null) {
      // सिर्फ एक तारीख (उसी दिन)
      whereClause = 'DATE(created_at) = DATE(?)';
      whereArgs = [startDate.toIso8601String()];
    }
    // अगर कोई तारीख नहीं है, तो whereClause null रहेगा (सब कुछ दिखाओ)

    final List<Map<String, dynamic>> maps = await db.query(
      'Lists',
      orderBy: 'id DESC',
      where: whereClause,
      whereArgs: whereArgs,
    );

    return List.generate(maps.length, (i) {
      return ShoppingList.fromMap(maps[i]);
    });
  }

  // (Delete List हम बाद में जोड़ेंगे)

  // ---------- 5. ListItems के लिए फंक्शन्स ----------

  // किसी खास लिस्ट के सारे आइटम पाना
  Future<List<ShoppingItem>> getItemsForList(int listId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ListItems',
      where: 'list_id = ?', // सिर्फ उस लिस्ट के आइटम
      whereArgs: [listId],
    );

    return List.generate(maps.length, (i) {
      return ShoppingItem.fromMap(maps[i]);
    });
  }

  // किसी खास लिस्ट में नया आइटम जोड़ना
  Future<int> insertItem(ShoppingItem item) async {
    Database db = await instance.database;
    // .toMap() में 'list_id' होना ज़रूरी है (हम यह model में सेट करेंगे)
    return await db.insert('ListItems', item.toMap());
  }

  // आइटम को अपडेट करना (Check/Uncheck, Price)
  Future<int> updateItem(ShoppingItem item) async {
    Database db = await instance.database;
    return await db.update(
      'ListItems',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> toggleListFavorite(int listId, bool isFavorite) async {
    Database db = await instance.database;
    await db.update(
      'Lists',
      {'is_favorite': isFavorite ? 1 : 0}, // 1 = true, 0 = false
      where: 'id = ?',
      whereArgs: [listId],
    );
  }

  // आइटम को डिलीट करना
  Future<int> deleteItem(int id) async {
    Database db = await instance.database;
    return await db.delete(
      'ListItems',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteList(int id) async {
    Database db = await instance.database;
    return await db.delete(
      'Lists',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ShoppingList>> getFavoriteLists() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Lists',
      where: 'is_favorite = ?', // केवल पसंदीदा लिस्ट
      whereArgs: [1], // 1 = true
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) {
      return ShoppingList.fromMap(maps[i]);
    });
  }
  // --- 2. Export के लिए पूरा डेटा निकालना ---
  Future<Map<String, dynamic>> getFullDatabase() async {
    Database db = await instance.database;

    // सारी लिस्ट लें
    final lists = await db.query('Lists');
    // सारे आइटम लें
    final items = await db.query('ListItems');

    return {
      'lists': lists,
      'items': items,
    };
  }

  // --- 3. Import करना (JSON डेटा से) ---
  Future<void> importDatabase(Map<String, dynamic> data) async {
    Database db = await instance.database;

    // (Optional: आप चाहें तो पुराना डेटा पहले डिलीट कर सकते हैं)
    // await deleteAllData();

    final List<dynamic> lists = data['lists'];
    final List<dynamic> items = data['items'];

    // बैच (Batch) का उपयोग करें ताकि काम तेज़ हो
    final batch = db.batch();

    // हम पुरानी ID का इस्तेमाल नहीं कर सकते क्योंकि वो शायद पहले से मौजूद हों।
    // इसलिए हम एक मैप बनाएँगे: OldID -> NewID
    Map<int, int> listIdMap = {};

    for (var listMap in lists) {
      // 1. पुरानी ID सेव करें
      int oldId = listMap['id'];

      // 2. लिस्ट का डेटा कॉपी करें (ID हटाकर)
      Map<String, dynamic> newListMap = Map.from(listMap);
      newListMap.remove('id'); // नई ID अपने आप बनेगी

      // 3. नई लिस्ट बनाएँ और उसकी नई ID पाएँ
      int newId = await db.insert('Lists', newListMap);
      listIdMap[oldId] = newId; // मैप करें
    }

    for (var itemMap in items) {
      Map<String, dynamic> newItemMap = Map.from(itemMap);
      newItemMap.remove('id'); // नई आइटम ID

      // 4. पुरानी ListID को नई ListID से बदलें
      int oldListId = newItemMap['list_id'];
      if (listIdMap.containsKey(oldListId)) {
        newItemMap['list_id'] = listIdMap[oldListId];
        // 5. आइटम को सेव करें
        await db.insert('ListItems', newItemMap);
      }
    }
  }
}