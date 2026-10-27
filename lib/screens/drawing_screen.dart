import 'dart:convert'; // Import JSON support
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:path_provider/path_provider.dart';

// --- HELPER FUNCTIONS FOR COLOR CONVERSION ---
String colorToHex(Color color) {
  return '#${color.value.toRadixString(16).padLeft(8, '0')}';
}

Color hexToColor(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

// --- UPDATED MODEL: Supports JSON Serialization ---
class DrawnLine {
  final List<Offset> path;
  final Color color;
  final double width;

  DrawnLine({required this.path, required this.color, required this.width});

  // Convert Object to JSON Map
  Map<String, dynamic> toJson() {
    return {
      'path': path.map((e) => {'dx': e.dx, 'dy': e.dy}).toList(),
      'color': colorToHex(color),
      'width': width,
    };
  }

  // Create Object from JSON Map
  factory DrawnLine.fromJson(Map<String, dynamic> json) {
    var pathList = json['path'] as List;
    List<Offset> pathItems = pathList.map((e) => Offset(e['dx'], e['dy'])).toList();
    return DrawnLine(
      path: pathItems,
      color: hexToColor(json['color']),
      width: (json['width'] as num).toDouble(),
    );
  }
}

// --- UPDATED DRAWING SCREEN WIDGET ---
class DrawingScreen extends StatefulWidget {
  // Naya parameter: Agar purani drawing edit karni hai to yahan data aayega
  final String? initialData;

  const DrawingScreen({super.key, this.initialData});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  List<DrawnLine> _lines = [];
  List<DrawnLine> _redoLines = [];

  Color _selectedColor = Colors.black;
  double _strokeWidth = 5.0;
  List<Offset> _currentPath = [];
  bool _isEraserMode = false;

  @override
  void initState() {
    super.initState();
    // Agar purana data hai, to use load karo
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      _loadInitialData();
    }
  }

  // Function to load existing drawing data
  void _loadInitialData() {
    try {
      // Prefix hatakar JSON decode karo
      String jsonString = widget.initialData!.replaceFirst("[DRAWING_DATA]:", "");
      List<dynamic> jsonList = jsonDecode(jsonString);
      setState(() {
        _lines = jsonList.map((e) => DrawnLine.fromJson(e)).toList();
      });
    } catch (e) {
      print("Error loading drawing data: $e");
    }
  }


  // --- ACTIONS ---
  void _undo() {
    if (_lines.isNotEmpty) {
      setState(() {
        _redoLines.add(_lines.removeLast());
      });
    }
  }

  void _redo() {
    if (_redoLines.isNotEmpty) {
      setState(() {
        _lines.add(_redoLines.removeLast());
      });
    }
  }

  void _clearCanvas() {
    setState(() {
      _lines.clear();
      _redoLines.clear();
    });
  }

  void _toggleEraser() {
    setState(() {
      _isEraserMode = !_isEraserMode;
    });
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a custom color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _isEraserMode ? Colors.black : _selectedColor,
            onColorChanged: (color) {
              setState(() {
                _selectedColor = color;
                _isEraserMode = false;
              });
            },
            showLabel: false,
            enableAlpha: false,
            displayThumbColor: true,
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('Done'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // --- NEW SAVE LOGIC: Saves Data, Not Image ---
  void _saveDrawingData() {
    if (_lines.isEmpty) {
      Navigator.pop(context);
      return;
    }

    try {
      // 1. Saari lines ko JSON list mein convert karo
      List<Map<String, dynamic>> jsonList = _lines.map((line) => line.toJson()).toList();

      // 2. JSON string banao
      String jsonString = jsonEncode(jsonList);

      // 3. Ek prefix lagado taaki pata chale ye drawing data hai
      String finalData = "[DRAWING_DATA]:$jsonString";

      // 4. Wapas pichli screen par data bhej do
      if (mounted) Navigator.pop(context, finalData);

    } catch (e) {
      print("Error saving drawing data: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error saving drawing data")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Drawing Board", style: TextStyle(color: Colors.black, fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.blue, size: 30),
            onPressed: _saveDrawingData, // Call new save function
          ),
        ],
      ),
      body: Stack(
        children: [
          // --- LAYER 1: DRAWING CANVAS ---
          GestureDetector(
            onPanStart: (details) {
              setState(() {
                _currentPath = [details.localPosition];
                _redoLines.clear();
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _currentPath.add(details.localPosition);
              });
            },
            onPanEnd: (details) {
              setState(() {
                _lines.add(DrawnLine(
                  path: List.from(_currentPath),
                  color: _isEraserMode ? Colors.white : _selectedColor,
                  width: _strokeWidth,
                ));
                _currentPath = [];
              });
            },
            child: RepaintBoundary(
              child: CustomPaint(
                painter: DrawingPainter(
                    _lines,
                    currentPath: _currentPath,
                    currentColor: _isEraserMode ? Colors.white : _selectedColor,
                    currentWidth: _strokeWidth
                ),
                size: Size.infinite,
              ),
            ),
          ),

          // --- LAYER 2: BOTTOM TOOLBAR ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- ROW 1: Quick Colors & Tools ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Quick Colors
                      Row(
                        children: [
                          _buildColorCircle(Colors.black),
                          _buildColorCircle(Colors.redAccent),
                          _buildColorCircle(Colors.blueAccent),
                          _buildColorCircle(Colors.green),
                          _buildColorCircle(Colors.amber),
                          // Custom Picker
                          GestureDetector(
                            onTap: _pickColor,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 30, height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(colors: [Colors.red, Colors.blue, Colors.green]),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Eraser Toggle
                      IconButton(
                        onPressed: _toggleEraser,
                        icon: Icon(
                          _isEraserMode ? Icons.cleaning_services : Icons.cleaning_services_outlined,
                          color: _isEraserMode ? Colors.blue : Colors.grey,
                        ),
                        tooltip: "Eraser",
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  const Divider(),

                  // --- ROW 2: Slider & Actions ---
                  Row(
                    children: [
                      const Text("Size", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Slider(
                          value: _strokeWidth,
                          min: 2.0,
                          max: 20.0,
                          activeColor: _isEraserMode ? Colors.grey : _selectedColor,
                          inactiveColor: Colors.grey[200],
                          onChanged: (val) => setState(() => _strokeWidth = val),
                        ),
                      ),
                      // Undo
                      IconButton(
                        icon: Icon(Icons.undo, color: _lines.isEmpty ? Colors.grey : Colors.black),
                        onPressed: _lines.isEmpty ? null : _undo,
                      ),
                      // Redo
                      IconButton(
                        icon: Icon(Icons.redo, color: _redoLines.isEmpty ? Colors.grey : Colors.black),
                        onPressed: _redoLines.isEmpty ? null : _redo,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorCircle(Color color) {
    bool isSelected = !_isEraserMode && _selectedColor == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
          _isEraserMode = false;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.blue, width: 3)
              : Border.all(color: Colors.grey.shade200),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 5)] : null,
        ),
      ),
    );
  }
}

// --- CUSTOM PAINTER (With Smooth Lines) ---
class DrawingPainter extends CustomPainter {
  final List<DrawnLine> lines;
  final List<Offset>? currentPath;
  final Color? currentColor;
  final double? currentWidth;

  DrawingPainter(this.lines, {this.currentPath, this.currentColor, this.currentWidth});

  @override
  void paint(Canvas canvas, Size size) {
    for (var line in lines) {
      _paintLine(canvas, line.path, line.color, line.width);
    }
    if (currentPath != null && currentPath!.isNotEmpty) {
      _paintLine(canvas, currentPath!, currentColor ?? Colors.black, currentWidth ?? 5.0);
    }
  }

  void _paintLine(Canvas canvas, List<Offset> points, Color color, double width) {
    if (points.isEmpty) return;
    if (points.length < 2) {
      canvas.drawCircle(points.first, width / 2, Paint()..color = color);
      return;
    }

    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    Path path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      Offset p1 = points[i];
      Offset p2 = points[i + 1];
      Offset midPoint = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      if (i == 0) {
        path.lineTo(p1.dx, p1.dy);
      }
      path.quadraticBezierTo(p1.dx, p1.dy, midPoint.dx, midPoint.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}