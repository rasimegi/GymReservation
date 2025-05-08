class Announcement {
  final String id;
  final String aTitle;
  final String message;

  Announcement({required this.id, required this.aTitle, required this.message});

  factory Announcement.fromJson(Map<String, dynamic> json, String documentId) {
    return Announcement(
      id: documentId,
      aTitle: json['aTitle'] ?? '',
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'aTitle': aTitle, 'message': message};
  }
}
