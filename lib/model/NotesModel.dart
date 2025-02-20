class Note {
  String title;
  String content;
  String createdDate;
  bool important;

  Note({
    required this.title,
    required this.content,
    required this.createdDate,
    this.important = false,
  });

  // Convert a Note object to a Map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'createdDate': createdDate,
      'important': important,
    };
  }

  // Create a Note object from a Map
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdDate: map['createdDate'] ?? '',
      important: map['important'] ?? false,
    );
  }
}
