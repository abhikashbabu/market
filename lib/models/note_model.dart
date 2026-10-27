class Note {
  final int? id;
  final String title;
  final String content;
  final String date;
  final int colorIndex; // नोट के रंग के लिए

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.date,
    this.colorIndex = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date,
      'color_index': colorIndex,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      date: map['date'],
      colorIndex: map['color_index'] ?? 0,
    );
  }
}