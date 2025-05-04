class UserModel {
  final String uid;
  final String email;
  final String username;
  final String? fullName;
  final String? phoneNumber;
  final String? profileImageUrl;
  final DateTime? birthDate;
  final String? gender;
  
  // İsteğe bağlı ek bilgiler
  final Map<String, dynamic>? additionalInfo;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.fullName,
    this.phoneNumber,
    this.profileImageUrl,
    this.birthDate,
    this.gender,
    this.additionalInfo,
  });

  // Firestore'dan gelen verilerle UserModel oluştur
  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      uid: id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      fullName: data['fullName'],
      phoneNumber: data['phoneNumber'],
      profileImageUrl: data['profileImageUrl'],
      birthDate: data['birthDate'] != null 
          ? (data['birthDate'] as Timestamp).toDate() 
          : null,
      gender: data['gender'],
      additionalInfo: data['additionalInfo'],
    );
  }

  // UserModel'i Firestore için Map'e dönüştür
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'username': username,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'birthDate': birthDate,
      'gender': gender,
      'additionalInfo': additionalInfo,
    };
  }
  
  // Güncellenmiş UserModel kopyası oluştur
  UserModel copyWith({
    String? email,
    String? username,
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
    DateTime? birthDate,
    String? gender,
    Map<String, dynamic>? additionalInfo,
  }) {
    return UserModel(
      uid: this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      additionalInfo: additionalInfo ?? this.additionalInfo,
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