import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../database_helper.dart';
import '../models/note_model.dart';
import 'drawing_screen.dart'; // Ensure ye file exist karti ho

class AddNoteScreen extends StatefulWidget {
  final Note? note;
  const AddNoteScreen({super.key, this.note});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final dbHelper = DatabaseHelper.instance;

  late stt.SpeechToText _speech;
  bool _isListening = false;

  // --- COLORS ---
  final Color _customBgColor = const Color(0xFF141007); // Dark Background
  final Color _customTextColor = const Color(0xFFF2E4DC); // Text & Cursor Color

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
    }
  }

  void _saveNote() async {
    // Agar title aur content dono khali hain to save mat karo
    if (_titleController.text.isEmpty && _contentController.text.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final note = Note(
      id: widget.note?.id,
      title: _titleController.text,
      content: _contentController.text,
      date: DateFormat('MMM dd, yyyy').format(DateTime.now()),
      colorIndex: widget.note?.colorIndex ?? 0,
    );

    if (widget.note == null) {
      await dbHelper.insertNote(note);
    } else {
      await dbHelper.updateNote(note);
    }
    if (mounted) Navigator.pop(context);
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          localeId: 'hi_IN',
          onResult: (val) {
            setState(() {
              var currentText = _contentController.text;
              var newText = val.recognizedWords;
              // Agar drawing mode mein ho to text append mat hone dena
              if (!currentText.startsWith("[DRAWING_DATA]:")) {
                _contentController.text = "$currentText $newText";
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

  // --- EDIT DRAWING FUNCTION ---
  void _editDrawing(String drawingData) async {
    // Drawing screen kholo aur purana data pass karo
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DrawingScreen(initialData: drawingData)),
    );

    // Agar wahan se naya data aaya (save kiya), to update karo
    if (result != null && mounted) {
      setState(() {
        _contentController.text = result;
      });
      // Drawing update hone ke baad auto-save karein
      _saveNote();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check karein ki kya ye Note Drawing hai ya normal Text
    bool isDrawing = _contentController.text.startsWith("[DRAWING_DATA]:");

    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: _customTextColor,
          selectionColor: _customTextColor.withOpacity(0.3),
          selectionHandleColor: _customTextColor,
        ),
      ),
      child: Scaffold(
        backgroundColor: _customBgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: _customTextColor),
            onPressed: _saveNote,
          ),
          actions: [
            // Agar Drawing mode hai to Mic button hide kar sakte hain ya disable
            if (!isDrawing)
              IconButton(
                icon: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: _isListening ? Colors.redAccent : _customTextColor,
                ),
                onPressed: _listen,
              ),
            IconButton(
              icon: Icon(Icons.check, color: _customTextColor),
              onPressed: _saveNote,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            children: [
              // --- TITLE INPUT ---
              TextField(
                controller: _titleController,
                cursorColor: _customTextColor,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _customTextColor,
                  fontFamily: 'Roboto',
                ),
                decoration: InputDecoration(
                  hintText: "Title",
                  hintStyle: TextStyle(
                    color: _customTextColor.withOpacity(0.5),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                  border: InputBorder.none,
                ),
              ),

              const SizedBox(height: 10),

              // --- CONTENT AREA (LOGIC UPDATED HERE) ---
              Expanded(
                child: isDrawing
                    ?
                // CASE 1: Agar Drawing hai to BUTTON dikhao
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.palette_outlined, size: 80, color: _customTextColor.withOpacity(0.5)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _customTextColor, // Button cream color
                            foregroundColor: _customBgColor, // Text dark brown
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                        ),
                        onPressed: () {
                          _editDrawing(_contentController.text);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text("Edit Drawing", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "This note contains a drawing.",
                        style: TextStyle(color: _customTextColor.withOpacity(0.6)),
                      ),
                    ],
                  ),
                )
                    :
                // CASE 2: Agar Normal Text hai to TEXTFIELD dikhao
                TextField(
                  controller: _contentController,
                  cursorColor: _customTextColor,
                  style: TextStyle(
                    fontSize: 18,
                    color: _customTextColor,
                    height: 1.5,
                  ),
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: "Note something down...",
                    hintStyle: TextStyle(
                      color: _customTextColor.withOpacity(0.5),
                      fontSize: 18,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}