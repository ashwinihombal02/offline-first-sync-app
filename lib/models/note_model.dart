class NoteModel {
  final String id;
  final String title;
  final bool isSaved;
  final DateTime updatedAt;

  NoteModel({
    required this.id,
    required this.title,
    required this.isSaved,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isSaved': isSaved,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'],
      title: map['title'],
      isSaved: map['isSaved'] ?? false,
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}