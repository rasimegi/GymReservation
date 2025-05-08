class TrainingProgram {
  final String id;
  final String title;
  final String description;
  final String uid;

  TrainingProgram({
    required this.id,
    required this.title,
    required this.description,
    required this.uid,
  });

  factory TrainingProgram.fromJson(
    Map<String, dynamic> json,
    String documentId,
  ) {
    return TrainingProgram(
      id: documentId,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      uid: json['uid'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'description': description, 'uid': uid};
  }
}
