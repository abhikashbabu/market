// lib/utils/voice_parser.dart
import '../models/shopping_item.dart';

class VoiceParser {
  // (Word-to-Digit मैप - यह सही है)
  static final Map<String, String> _wordToDigit = {
    'pan sau': '500', 'paanch sau': '500', 'ek sau': '100',
    'do sau': '200', 'teen sau': '300', 'ek hazaar': '1000',
    'pachas': '50', 'chaalis': '40', 'tees': '30',
    'bees': '20', 'das': '10'
  };

  // --- 1. (नया) Text Interchange/Replacement मैप ---
  // (आप इसमें जितने चाहें, उतने शब्द जोड़ सकते हैं)
  static final Map<String, String> _unitReplacements = {
    'kilo gram': 'kg', // आपका अनुरोध
    'kilogram': 'kg',
    'kilo': 'kg',      // आपका अनुरोध
    'किलो': 'kg',
    'gram': 'g',
    'ग्राम': 'g',
    'liter': 'ltr',
    'litre': 'ltr',
    'लीटर': 'ltr',
    'piece': 'pc',
    'पीस': 'pc',
    'packet': 'pkt',
    'पैकेट': 'pkt',
    'pack': 'pkt',
    'पैक': 'pkt',
  };
  // ------------------------------------------------

  static List<ShoppingItem> parse(String rawText, int listId) {
    List<ShoppingItem> items = [];
    final RegExp splitRegex = RegExp(r',| aur | and | और ');
    List<String> parts = rawText.toLowerCase().split(splitRegex);

    for (String part in parts) {
      if (part.trim().isNotEmpty) {
        ShoppingItem? item = _parseSingleItem(part, listId);
        if (item != null) {
          items.add(item);
        }
      }
    }
    return items;
  }

  static ShoppingItem? _parseSingleItem(String text, int listId) {
    String originalText = text;

    // 1. प्री-प्रोसेसिंग: शब्दों को अंकों में बदलें
    for (String key in _wordToDigit.keys) {
      if (text.contains(key)) {
        text = text.replaceAll(key, _wordToDigit[key]!);
      }
    }

    // 2. कीमत (Price) ढूँढें और हटा दें
    double? estimatedPrice;
    final RegExp priceRegex = RegExp(r'(\d+(\.\d+)?)\s*(rupay|rupya|rs|₹|रुपये|रुपए)');
    final RegExp pricePrefixRegex = RegExp(r'(rupay|rupya|rs|₹|रुपये|रुपए)\s*(\d+(\.\d+)?)');

    Match? priceMatch = priceRegex.firstMatch(text);
    if (priceMatch != null) {
      estimatedPrice = double.tryParse(priceMatch.group(1)!);
      text = text.replaceFirst(priceMatch.group(0)!, ' ').trim();
    } else {
      Match? pricePrefixMatch = pricePrefixRegex.firstMatch(text);
      if (pricePrefixMatch != null) {
        estimatedPrice = double.tryParse(pricePrefixMatch.group(2)!);
        text = text.replaceFirst(pricePrefixMatch.group(0)!, ' ').trim();
      }
    }

    // --- 3. (नया) Text Interchange (टेक्स्ट को बदलें) ---
    // (कीमत हटने के बाद, बचे हुए टेक्स्ट में शब्दों को बदलें)
    for (String key in _unitReplacements.keys) {
      if (text.contains(key)) {
        // 'replaceAll' का इस्तेमाल करें ताकि "kilo" अगर दो बार आए तो दोनों बार बदले
        text = text.replaceAll(key, _unitReplacements[key]!);
      }
    }
    // --------------------------------------------------

    // 4. जो कुछ भी बचा वह आइटम का नाम है
    String itemName = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    // 5. फॉलबैक केस
    if (itemName.isEmpty && estimatedPrice == null) {
      return null;
    }
    if (itemName.isEmpty && estimatedPrice != null) {
      print("Parse Warning: No item name found for '$originalText'");
      return null;
    }

    return ShoppingItem(
      listId: listId,
      itemName: itemName, // <-- "20 kg aalu" (बदला हुआ)
      quantity: null,
      unit: null,
      estimatedPrice: estimatedPrice ?? 0.0,
    );
  }
}