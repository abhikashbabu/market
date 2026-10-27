import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../database_helper.dart';
import '../models/note_model.dart';
import 'add_note_screen.dart';
import 'voice_note_screen.dart'; // Import Voice Screen
import 'drawing_screen.dart';   // Import Drawing Screen

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> with SingleTickerProviderStateMixin {
  final dbHelper = DatabaseHelper.instance;
  List<Note> _allNotes = [];
  List<Note> _filteredNotes = [];
  bool _isFabExpanded = false;
  late AnimationController _animationController;

  // --- NEW COLOR PALETTE ---
  final Color _lightBg = const Color(0xFFF0F0F0);

  // Dark Mode "Bhura" (Sepia Dark) Theme Colors
  final Color _sepiaDarkBg = const Color(0xFF141007); // Main App Background (Deep Brown/Black mix)
  final Color _sepiaCardBg = const Color(0xFF261F19); // Card Background
  final Color _sepiaBorder = const Color(0xFF3C2E25); // Border Color
  final Color _sepiaFabAccent = const Color(0xFFE6C9A8); // FAB Color (Cream/Peach)

  // Note Card Colors (Light Mode Only)
  final List<Color> _lightNoteColors = [
    const Color(0xFFFFF475), // Classic Yellow
    const Color(0xFFF28B82), // Red
    const Color(0xFFFBBC04), // Orange
    const Color(0xFFCCFF90), // Green
    const Color(0xFFA7FFEB), // Teal
    const Color(0xFFCBF0F8), // Blue
    const Color(0xFFE6C9A8), // Brown
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _loadNotes();
  }

  void _loadNotes() async {
    final notes = await dbHelper.getNotes();
    setState(() {
      _allNotes = notes;
      _filteredNotes = notes;
    });
  }

  void _filterNotes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredNotes = _allNotes;
      } else {
        _filteredNotes = _allNotes.where((note) =>
        note.title.toLowerCase().contains(query.toLowerCase()) ||
            note.content.toLowerCase().contains(query.toLowerCase())).toList();
      }
    });
  }

  void _deleteNote(int id) async {
    await dbHelper.deleteNote(id);
    _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme Colors Apply
    Color bgColor = isDark ? _sepiaDarkBg : _lightBg;
    Color textColor = isDark ? const Color(0xFFF2E4DC) : Colors.black; // Cream text in dark mode

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 10),
                // --- Search Bar ---
                _buildSearchBar(isDark, textColor),

                // --- Masonry Grid ---
                Expanded(
                  child: _filteredNotes.isEmpty
                      ? _buildEmptyState(isDark)
                      : MasonryGridView.count(
                    padding: const EdgeInsets.all(12),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    itemCount: _filteredNotes.length,
                    itemBuilder: (context, index) {
                      return _buildNoteCard(_filteredNotes[index], isDark);
                    },
                  ),
                ),
              ],
            ),

            // --- Expanding FAB Backdrop (Click to close) ---
            if (_isFabExpanded) _buildExpandedFabBackground(),

            // --- FAB Menu ---
            Positioned(
              bottom: 25,
              right: 20,
              child: _buildFabMenu(isDark),
            ),
          ],
        ),
      ),
    );
  }

  // --- Search Bar ---
  Widget _buildSearchBar(bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? _sepiaCardBg : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: isDark ? _sepiaBorder : Colors.grey.shade300
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: TextField(
          style: TextStyle(color: textColor, fontSize: 16),
          onChanged: _filterNotes,
          decoration: InputDecoration(
            hintText: "Search your notes...",
            hintStyle: TextStyle(
                color: isDark ? textColor.withOpacity(0.5) : Colors.grey[600]),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            suffixIcon: Icon(Icons.search, color: isDark ? textColor.withOpacity(0.7) : Colors.grey),
          ),
        ),
      ),
    );
  }

  // --- The NOTE CARD ---
  Widget _buildNoteCard(Note note, bool isDark) {
    Color bg = isDark
        ? _sepiaCardBg
        : _lightNoteColors[note.colorIndex % _lightNoteColors.length];

    Color borderBg = isDark
        ? _sepiaBorder
        : Colors.transparent;

    Color cardTextColor = isDark ? const Color(0xFFF2E4DC) : Colors.black87;

    // Check karein ki ye Drawing hai ya normal text
    bool isDrawing = note.content.startsWith("[DRAWING_DATA]:");

    // Check karein ki note chhota hai ya bada (Text ke liye)
    bool isShortNote = note.content.length < 50;

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => AddNoteScreen(note: note)))
            .then((_) => _loadNotes());
      },
      onLongPress: () => _deleteNote(note.id!),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderBg, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (note.title.isNotEmpty) ...[
              Text(
                note.title,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cardTextColor,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // --- MAIN CONTENT LOGIC ---
            isDrawing
                ?
            // AGAR DRAWING HAI TO YE DIKHAO:
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.white54,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cardTextColor.withOpacity(0.1))
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.brush, size: 40, color: cardTextColor.withOpacity(0.7)),
                  const SizedBox(height: 5),
                  Text(
                    "Drawing / Sketch",
                    style: TextStyle(
                        fontSize: 12,
                        color: cardTextColor.withOpacity(0.5),
                        fontWeight: FontWeight.bold
                    ),
                  )
                ],
              ),
            )
                :
            // AGAR NORMAL TEXT HAI TO YE DIKHAO:
            Text(
              note.content,
              maxLines: 12,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isShortNote ? 18 : 15,
                height: 1.4,
                fontWeight: isShortNote ? FontWeight.w500 : FontWeight.normal,
                color: cardTextColor.withOpacity(0.9),
              ),
            ),
            // ---------------------------

            const SizedBox(height: 12),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                note.date,
                style: TextStyle(
                    fontSize: 10,
                    color: cardTextColor.withOpacity(0.5),
                    fontWeight: FontWeight.bold
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // --- FAB MENU (UPDATED) ---
  Widget _buildFabMenu(bool isDark) {
    // Earthy Colors for Buttons
    final Color drawingColor = isDark ? const Color(0xFFAED581) : Colors.lightGreen;
    final Color voiceColor = isDark ? const Color(0xFFFF8A65) : Colors.orangeAccent;
    final Color textColor = isDark ? const Color(0xFF4DB6AC) : Colors.tealAccent.shade700;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isFabExpanded) ...[
          // 1. DRAWING BUTTON
          _buildFabOption(
              icon: Icons.brush,
              label: "Drawing",
              color: drawingColor,
              isDark: isDark,
              onTap: () async {
                _toggleFab();
                // Drawing Screen kholo (bina initial data ke)
                final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DrawingScreen())
                );

                // Agar save kiya (result null nahi hai)
                if (result != null && mounted) {
                  // Note banao. Content me ab lamba chawda drawing data string hoga.
                  await dbHelper.insertNote(Note(
                      title: "Drawing Note", // Aap chahein to user se title maang sakte hain
                      content: result, // Ye ab file path nahi, drawing data hai
                      date: DateTime.now().toString(),
                      colorIndex: 0
                  ));
                  _loadNotes();
                }
              }
          ),
          const SizedBox(height: 12),

          // 2. VOICE BUTTON
          _buildFabOption(
              icon: Icons.mic,
              label: "Voice",
              color: voiceColor,
              isDark: isDark,
              onTap: () {
                _toggleFab();
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const VoiceNoteScreen())
                ).then((_) => _loadNotes());
              }
          ),
          const SizedBox(height: 12),

          // 3. TEXT BUTTON
          _buildFabOption(
              icon: Icons.text_fields,
              label: "Text",
              color: textColor,
              isDark: isDark,
              onTap: () {
                _toggleFab();
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddNoteScreen())
                ).then((_) => _loadNotes());
              }
          ),
          const SizedBox(height: 16),
        ],

        // MAIN TOGGLE BUTTON
        FloatingActionButton(
          onPressed: _toggleFab,
          backgroundColor: _sepiaFabAccent,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _animationController,
            color: const Color(0xFF141007), // Dark icon
          ),
        ),
      ],
    );
  }

  // --- FAB OPTION WIDGET (UPDATED LOGIC) ---
  Widget _buildFabOption({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap // Added onTap callback
  }) {

    final Color labelBg = isDark ? const Color(0xFF261F19) : Colors.white;
    final Color labelText = isDark ? const Color(0xFFF2E4DC) : Colors.black;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: labelBg,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.3)
              )
            ],
            border: isDark ? Border.all(color: const Color(0xFF3C2E25)) : null,
          ),
          child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: labelText,
                fontSize: 14,
              )
          ),
        ),
        const SizedBox(width: 12),
        FloatingActionButton.small(
          onPressed: onTap, // Use the passed function
          backgroundColor: color,
          child: Icon(icon, color: const Color(0xFF141007)),
        ),
      ],
    );
  }

  Widget _buildExpandedFabBackground() {
    return GestureDetector(
      onTap: _toggleFab,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          color: Colors.black.withOpacity(0.4),
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lightbulb_outline, size: 80, color: isDark ? Colors.white24 : Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(
            "Apke notes yahan dikhenge",
            style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
          ),
        ],
      ),
    );
  }

  void _toggleFab() {
    setState(() {
      _isFabExpanded = !_isFabExpanded;
      if (_isFabExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }
}