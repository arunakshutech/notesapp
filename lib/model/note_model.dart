
class Note {
  String? title;
  String? createdDate;
  String? category;
  String? tags;
  String? content;
  bool important;
  String? imageUrl;

  Note({
    this.title,
    this.createdDate,
    this.category,
    this.content,
    this.tags,
    this.important = false,
    this.imageUrl
  });

  // Convert a Note into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'createdDate': createdDate,
      'category': category,
      'content':content,
      'tags':tags,
      'important': important,
      'imageUrl':imageUrl
    };
  }

  // Extract a Note object from a Map.
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      title: map['title'],
      createdDate: map['createdDate'],
      category: map['category'],
      content: map['content'],
      tags: map['tags'],
      important: map['important'],
      imageUrl:map['imageUrl']
    );
  }
}
