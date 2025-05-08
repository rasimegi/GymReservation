class MeasurementsModel {
  final String measurementId; // Ölçüm ID'si (measID_timestamp formatında)
  final String userId; // Kullanıcı ID'si
  final String mDate; // Ölçüm tarihi (YYYY-MM-DD formatında)
  final double weight; // Kilo (kg)
  final double height; // Boy (cm)
  final double chest; // Göğüs (cm)
  final double waist; // Bel (cm)
  final double hip; // Kalça (cm)
  final double arm; // Kol (cm)
  final double thigh; // Uyluk (cm)
  final double shoulder; // Omuz (cm)
  final double age; // Yaş
  final String gender; // Cinsiyet ("Erkek" veya "Kadın")
  final String goal; // Hedef ("Kilo Vermek", "Kilo Almak", "Kas Kazanmak" vb.)
  final String
  activityLevel; // Aktivite seviyesi ("Düşük Seviye", "Orta Seviye", "Yüksek Seviye")
  final String? updatedAt; // Güncellenme zamanı (ISO8601 formatında)

  MeasurementsModel({
    required this.measurementId,
    required this.userId,
    required this.mDate,
    required this.weight,
    required this.height,
    required this.chest,
    required this.waist,
    required this.hip,
    required this.arm,
    required this.thigh,
    required this.shoulder,
    required this.age,
    required this.gender,
    required this.goal,
    required this.activityLevel,
    this.updatedAt,
  });

  // Firestore'dan gelen verilerle MeasurementsModel oluştur
  factory MeasurementsModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return MeasurementsModel(
      measurementId: data['measurementId'] ?? id,
      userId: data['userId'] ?? '',
      mDate: data['mDate'] ?? '',
      weight: (data['weight'] ?? 0).toDouble(),
      height: (data['height'] ?? 0).toDouble(),
      chest: (data['chest'] ?? 0).toDouble(),
      waist: (data['waist'] ?? 0).toDouble(),
      hip: (data['hip'] ?? 0).toDouble(),
      arm: (data['arm'] ?? 0).toDouble(),
      thigh: (data['thigh'] ?? 0).toDouble(),
      shoulder: (data['shoulder'] ?? 0).toDouble(),
      age: (data['age'] ?? 0).toDouble(),
      gender: data['gender'] ?? 'Erkek',
      goal: data['goal'] ?? 'Kilo Vermek',
      activityLevel: data['activityLevel'] ?? 'Orta Seviye',
      updatedAt: data['updatedAt'],
    );
  }

  // MeasurementsModel'i Firestore için Map'e dönüştür
  Map<String, dynamic> toFirestore() {
    return {
      'measurementId': measurementId,
      'userId': userId,
      'mDate': mDate,
      'weight': weight,
      'height': height,
      'chest': chest,
      'waist': waist,
      'hip': hip,
      'arm': arm,
      'thigh': thigh,
      'shoulder': shoulder,
      'age': age,
      'gender': gender,
      'goal': goal,
      'activityLevel': activityLevel,
      'updatedAt': updatedAt ?? DateTime.now().toIso8601String(),
    };
  }

  // Vücut kitle indeksi hesapla (BMI)
  double calculateBMI() {
    if (height <= 0) return 0;
    // BMI = kilo(kg) / (boy(m) * boy(m))
    double heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  // Güncellenmiş MeasurementsModel kopyası oluştur
  MeasurementsModel copyWith({
    String? measurementId,
    String? userId,
    String? mDate,
    double? weight,
    double? height,
    double? chest,
    double? waist,
    double? hip,
    double? arm,
    double? thigh,
    double? shoulder,
    double? age,
    String? gender,
    String? goal,
    String? activityLevel,
    String? updatedAt,
  }) {
    return MeasurementsModel(
      measurementId: measurementId ?? this.measurementId,
      userId: userId ?? this.userId,
      mDate: mDate ?? this.mDate,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      chest: chest ?? this.chest,
      waist: waist ?? this.waist,
      hip: hip ?? this.hip,
      arm: arm ?? this.arm,
      thigh: thigh ?? this.thigh,
      shoulder: shoulder ?? this.shoulder,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      goal: goal ?? this.goal,
      activityLevel: activityLevel ?? this.activityLevel,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Timestamp sınıfı için basit bir tanımlama (firebase_core paketinden)
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
