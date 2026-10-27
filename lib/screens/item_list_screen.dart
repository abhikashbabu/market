import 'dart:ui'; // ब्लब्स के लिए
import 'package:flutter/material.dart';
import 'package:ghar_se_market/models/shopping_list.dart';
import 'package:ghar_se_market/screens/sync_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../database_helper.dart';
import '../models/shopping_item.dart';
import '../utils/voice_parser.dart';

class ItemListScreen extends StatefulWidget {
  final ShoppingList list;
  const ItemListScreen({super.key, required this.list});

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> with SingleTickerProviderStateMixin {
  final dbHelper = DatabaseHelper.instance;
  late Future<List<ShoppingItem>> _shoppingList;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _currentRecognizedText = "";
  bool _isTypingMode = false;
  final TextEditingController _textInputController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  bool _hasSaved = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _loadList();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _textInputController.dispose();
    _textFocusNode.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _loadList() {
    setState(() {
      _shoppingList = dbHelper.getItemsForList(widget.list.id!);
    });
  }

  void _enterTypingMode() {
    setState(() {
      _isTypingMode = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _textFocusNode.requestFocus();
    });
  }

  void _exitTypingMode() {
    setState(() {
      _isTypingMode = false;
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    // 1. डार्क मोड और कलर्स
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color themeColor = const Color(0xFF2563EB);

    final Color backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFF6F8FB);
    final Color glassColor = isDark ? Colors.white : Colors.white; // डार्क मोड में भी वाइट ओपेसिटी अच्छी लगती है
    final Color textColor = isDark ? Colors.white : Colors.grey.shade900;

    return Scaffold(
      extendBody: true, // बॉडी को बॉटम बार के पीछे जाने दें
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // --- बैकग्राउंड ब्लब्स (एक बार रेंडर होंगे, नो लैग) ---
          Positioned(
            top: -100,
            right: -50,
            child: _buildBlurBlob(Colors.blue.withOpacity(0.15)),
          ),
          Positioned(
            bottom: 200,
            left: -50,
            child: _buildBlurBlob(Colors.purple.withOpacity(0.15)),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),

                // --- Header (No Blur) ---
                _buildFastGlassHeader(themeColor, glassColor, textColor, isDark),

                const SizedBox(height: 12),

                // --- List ---
                Expanded(
                  child: FutureBuilder<List<ShoppingItem>>(
                    future: _shoppingList,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shopping_bag_outlined, size: 64, color: isDark ? Colors.white24 : Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'कोई सामान नहीं जुड़ा है।\n+ दबाकर सामान जोड़ें',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16, color: isDark ? Colors.white60 : Colors.grey.shade600),
                              ),
                            ],
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () async => _loadList(),
                        color: themeColor,
                        backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                        child: ListView.builder(
                          // नीचे पैडिंग ताकि इनपुट बार के पीछे कंटेंट न छुपे
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final item = snapshot.data![index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: _buildItemCard(item, index + 1, themeColor, isDark, glassColor, textColor),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // --- Bottom Input Bar (No Blur) ---
      bottomNavigationBar: _buildFastGlassInputBar(themeColor, glassColor, textColor, isDark),
    );
  }
  Widget _buildFastGlassHeader(
      Color themeColor,
      Color glassColor,
      Color textColor,
      bool isDark,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: fakeGlass(
        radius: 20,
        opacity: isDark ? 0.10 : 0.55,
        color: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
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

              const SizedBox(width: 16),

              // List Badge
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      themeColor,
                      themeColor.withOpacity(0.7)
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.list.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  widget.list.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),

              IconButton(
                onPressed: () {
                  _loadList();
                },
                icon: Icon(Icons.refresh, color: themeColor),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- 2. Optimized Input Bar ---
  Widget _buildFastGlassInputBar(
      Color themeColor, Color glassColor, Color textColor, bool isDark) {

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        left: 12,
        right: 12,
      ),
      child: fakeGlass(
        radius: 26,
        opacity: isDark ? 0.10 : 0.60,
        color: Colors.white,
        child: Container(
          height: 65,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  _isTypingMode ? Icons.mic : Icons.keyboard,
                  color: Colors.grey.shade500,
                ),
                onPressed: () {
                  setState(() {
                    _isTypingMode = !_isTypingMode;
                  });
                },
              ),

              Expanded(
                child: _isTypingMode
                    ? TextField(
                  controller: _textInputController,
                  focusNode: _textFocusNode,
                  decoration: InputDecoration(
                    hintText: "सामान लिखें...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                  ),
                  style: TextStyle(color: textColor),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      _parseAndSave(val);
                      _textInputController.clear();
                    }
                  },
                )
                    : GestureDetector(
                  onTap: _listen,
                  child: Row(
                    children: [
                      Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? themeColor : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isListening
                              ? (_currentRecognizedText.isEmpty
                              ? "Listening..."
                              : _currentRecognizedText)
                              : "Tap to speak...",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _isListening
                                ? themeColor
                                : Colors.grey.shade600,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),

              FloatingActionButton.small(
                heroTag: "sendBtn",
                backgroundColor: themeColor,
                elevation: 0,
                child: Icon(
                  _isTypingMode
                      ? Icons.arrow_upward
                      : (_isListening ? Icons.stop : Icons.mic),
                  color: Colors.white,
                ),
                onPressed: () {
                  if (_isTypingMode) {
                    if (_textInputController.text.trim().isNotEmpty) {
                      _parseAndSave(_textInputController.text.trim());
                      _textInputController.clear();
                    }
                  } else {
                    _listen();
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }


// lib/screens/item_list_screen.dart

  // --- 3. Optimized Item Card (Fixed Delete Button) ---
  Widget _buildItemCard(
      ShoppingItem item,
      int no,
      Color themeColor,
      bool isDark,
      Color glassColor,
      Color textColor,
      ) {
    return fakeGlass(
      radius: 18,
      opacity: isDark ? 0.06 : 0.95,
      color: Colors.white,
      child: GestureDetector(
        onTap: () => _showEditItemDialog(item),
        child: Container(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // index box
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "$no",
                    style: TextStyle(
                      color: themeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // checkbox
              GestureDetector(
                onTap: () {
                  _showEditItemDialog(item, markAsPurchased: true);
                },
                child: Icon(
                  item.isPurchased
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: item.isPurchased ? Colors.green : Colors.grey,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  item.itemName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration:
                    item.isPurchased ? TextDecoration.lineThrough : null,
                    color: textColor,
                  ),
                ),
              ),

              // Edit Button
              GestureDetector(
                onTap: () => _showEditItemDialog(item),
                child: Icon(Icons.edit, size: 20, color: Colors.blueGrey),
              ),
              const SizedBox(width: 16), // थोड़ा स्पेस बढ़ाएं

              // --- (FIXED) Delete Button ---
              GestureDetector(
                onTap: () {
                  // डिलीट कन्फर्मेशन (Optional but recommended)
                  // या सीधे डिलीट:
                  _deleteItem(item.id!);
                },
                child: Icon(Icons.delete_outline, size: 24, color: Colors.redAccent),
              ),
              // ----------------------------
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceChip(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  // --- Background Blob ---
  Widget _buildBlurBlob(Color color) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 80, spreadRadius: 40),
        ],
      ),
    );
  }

  // --- Logic Functions (As is) ---
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if ((val == 'notListening' || val == 'done') && _isListening) {
            setState(() { _isListening = false; _hasSaved = false; });
          }
        },
        onError: (val) {
          if (_isListening) { setState(() { _isListening = false; _hasSaved = false; }); }
        },
      );
      if (available) {
        setState(() { _isListening = true; _hasSaved = false; });
        _currentRecognizedText = "";
        _speech.listen(
          localeId: 'hi_IN',
          pauseFor: const Duration(seconds: 2),
          onResult: (val) {
            _currentRecognizedText = val.recognizedWords;
            if (val.finalResult && !_hasSaved) {
              setState(() => _hasSaved = true);
              _parseAndSave(_currentRecognizedText);
            }
            setState(() {});
          },
        );
      }
    } else {
      _speech.stop();
      if (!_hasSaved) { setState(() => _hasSaved = true); _parseAndSave(_currentRecognizedText); }
      setState(() => _isListening = false);
    }
  }

  void _parseAndSave(String rawText) async {
    if (rawText.isEmpty) return;
    List<ShoppingItem> newItems = VoiceParser.parse(rawText, widget.list.id!);
    if (newItems.isEmpty) return;
    for (var item in newItems) {
      if (item.itemName.isNotEmpty) {
        await dbHelper.insertItem(item);
      }
    }
    SyncService().uploadToCloud();
    _loadList();
  }

  void _showEditItemDialog(ShoppingItem item, {bool markAsPurchased = false}) {
    final itemNameController = TextEditingController(text: item.itemName);
    final estPriceController = TextEditingController(text: item.estimatedPrice == 0.0 ? '' : item.estimatedPrice.toStringAsFixed(0));
    final mktPriceController = TextEditingController(text: item.marketPrice == 0.0 ? '' : item.marketPrice.toStringAsFixed(0));
    final FocusNode mktFocusNode = FocusNode();

    if (markAsPurchased) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        mktFocusNode.requestFocus();
      });
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Edit Item", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: itemNameController,
                decoration: const InputDecoration(labelText: "Item Name"),
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: estPriceController,
                      decoration: const InputDecoration(labelText: "Est. Price"),
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: mktPriceController,
                      focusNode: mktFocusNode,
                      decoration: const InputDecoration(labelText: "Mkt. Price"),
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              child: const Text("Save", style: TextStyle(color: Colors.white)),
              onPressed: () {
                double estPrice = double.tryParse(estPriceController.text) ?? item.estimatedPrice;
                double mktPrice = double.tryParse(mktPriceController.text) ?? item.marketPrice;
                String newName = itemNameController.text.trim();

                ShoppingItem updatedItem = ShoppingItem(
                  id: item.id,
                  listId: item.listId,
                  itemName: newName.isEmpty ? item.itemName : newName,
                  quantity: null, unit: null, // Simple parser compliance
                  isPurchased: markAsPurchased || item.isPurchased,
                  estimatedPrice: estPrice,
                  marketPrice: mktPrice,
                );

                dbHelper.updateItem(updatedItem).then((_) => _loadList());
                SyncService().uploadToCloud();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleItemPurchased(ShoppingItem item, bool isPurchased) async {
    // This is handled by checkbox onTap logic now
  }

  void _deleteItem(int id) async {
    await dbHelper.deleteItem(id);
    SyncService().uploadToCloud();
    _loadList();
  }
}
Widget fakeGlass({
  required Widget child,
  double radius = 18,
  double opacity = 0.18,
  double borderOpacity = 0.30,
  Color? color,
}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: (color ?? Colors.white).withOpacity(opacity),
      border: Border.all(
        color: (color ?? Colors.white).withOpacity(borderOpacity),
        width: 1.3,
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
