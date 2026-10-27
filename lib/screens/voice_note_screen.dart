import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
// import 'add_note_screen.dart'; // Ab iski zaroorat nahi hai agar hum direct save kar rahe hain
import '../database_helper.dart'; // ✅ Database Helper Import zaroori hai
import '../models/note_model.dart';

class VoiceNoteScreen extends StatefulWidget {
  const VoiceNoteScreen({super.key});

  @override
  State<VoiceNoteScreen> createState() => _VoiceNoteScreenState();
}

class _VoiceNoteScreenState extends State<VoiceNoteScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = "Tap the mic and start speaking...";
  double _confidence = 1.0;

  // --- THEME COLORS ---
  final Color _bgColor = const Color(0xFF141007);
  final Color _textColor = const Color(0xFFF2E4DC);
  final Color _accentColor = const Color(0xFFFF8A65);

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          localeId: 'hi_IN',
          onResult: (val) {
            setState(() {
              _text = val.recognizedWords;
              if (val.hasConfidenceRating && val.confidence > 0) {
                _confidence = val.confidence;
              }
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // --- ✅ NEW SAVE LOGIC ---
  void _saveAndEdit() async {
    // 1. Agar mic chal raha hai to band karein
    if (_isListening) {
      _speech.stop();
    }

    // 2. Check karein ki kuch bola gaya hai ya nahi
    if (_text.isNotEmpty && _text != "Tap the mic and start speaking...") {

      // 3. Note Object banayein
      final note = Note(
        title: "Voice Note", // Default Title
        content: _text,      // Bola hua text
        date: DateTime.now().toString(),
        colorIndex: 0,       // Default color
      );

      // 4. Database mein Save karein
      await DatabaseHelper.instance.insertNote(note);

      print("Voice Note Saved: $_text");
    }

    // 5. List screen par wapas jayein (Notes refresh ho jayenge)
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: _textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Voice Note",
          style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: _accentColor),
            onPressed: _saveAndEdit, // Yahan naya function call hoga
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.topLeft,
              child: SingleChildScrollView(
                reverse: true,
                child: Text(
                  _text,
                  style: TextStyle(
                    fontSize: 24,
                    color: _textColor,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
          if (_isListening)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                "Listening... ${( _confidence * 100.0).toStringAsFixed(1)}%",
                style: TextStyle(color: _textColor.withOpacity(0.5)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: GestureDetector(
              onTap: _listen,
              child: Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening ? Colors.redAccent : _accentColor,
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening ? Colors.redAccent : _accentColor).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: const Color(0xFF141007),
                  size: 40,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}