class UserModel {
  final String uid;
  final String email;
  final String username;
  final String? name;
  final String? surname;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.name,
    this.surname,
  });

  // Firestore'dan gelen verilerle UserModel oluştur
  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      uid: id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      name: data['name'],
      surname: data['surname'],
    );
  }

  // UserModel'i Firestore için Map'e dönüştür
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'username': username,
      'name': name,
      'surname': surname,
    };
  }

  // Güncellenmiş UserModel kopyası oluştur
  UserModel copyWith({
    String? email,
    String? username,
    String? name,
    String? surname,
  }) {
    return UserModel(
      uid: this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      name: name ?? this.name,
      surname: surname ?? this.surname,
    );
  }
}

// Timestamp sınıfı için basit bir tanımlama
class Timestamp {
  final int seconds;
  final int nanoseconds;

  Timestamp(this.seconds, this.nanoseconds);

  DateTime toDate() {
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }

  static Timestamp fromDate(DateTime date) {
    final int milliseconds = date.millisecondsSinceEpoch;
    final int seconds = milliseconds ~/ 1000;
    final int nanoseconds = (milliseconds % 1000) * 1000000;
    return Timestamp(seconds, nanoseconds);
  }
}
