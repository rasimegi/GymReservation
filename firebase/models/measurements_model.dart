class MeasurementsModel {
  final String id;                 // Ölçüm ID'si (tarih formatı)
  final String userId;             // Kullanıcı ID'si
  final DateTime date;             // Ölçüm tarihi
  final double weight;             // Kilo (kg)
  final double? height;            // Boy (cm)
  final double? chest;             // Göğüs (cm)
  final double? waist;             // Bel (cm)
  final double? hip;               // Kalça (cm)
  final double? arm;               // Kol (cm)
  final double? leg;               // Bacak (cm)
  final double? bodyFatPercentage; // Vücut yağ oranı (%)
  final double? bmi;               // Vücut kitle indeksi
  final String? notes;             // Ekstra notlar
  
  MeasurementsModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.weight,
    this.height,
    this.chest,
    this.waist,
    this.hip,
    this.arm,
    this.leg,
    this.bodyFatPercentage,
    this.bmi,
    this.notes,
  });
  
  // Firestore'dan gelen verilerle MeasurementsModel oluştur
  factory MeasurementsModel.fromFirestore(Map<String, dynamic> data, String id) {
    return MeasurementsModel(
      id: id,
      userId: data['userId'] ?? '',
      date: data['date'] != null 
          ? (data['date'] as Timestamp).toDate() 
          : DateTime.now(),
      weight: (data['weight'] ?? 0).toDouble(),
      height: data['height']?.toDouble(),
      chest: data['chest']?.toDouble(),
      waist: data['waist']?.toDouble(),
      hip: data['hip']?.toDouble(),
      arm: data['arm']?.toDouble(),
      leg: data['leg']?.toDouble(),
      bodyFatPercentage: data['bodyFatPercentage']?.toDouble(),
      bmi: data['bmi']?.toDouble(),
      notes: data['notes'],
    );
  }
  
  // MeasurementsModel'i Firestore için Map'e dönüştür
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'weight': weight,
      'height': height,
      'chest': chest,
      'waist': waist,
      'hip': hip,
      'arm': arm,
      'leg': leg,
      'bodyFatPercentage': bodyFatPercentage,
      'bmi': bmi,
      'notes': notes,
    };
  }
  
  // Vücut kitle indeksi hesapla (BMI)
  double calculateBMI() {
    if (height == null || height! <= 0) return 0;
    // BMI = kilo(kg) / (boy(m) * boy(m))
    double heightInMeters = height! / 100;
    return weight / (heightInMeters * heightInMeters);
  }
  
  // Güncellenmiş MeasurementsModel kopyası oluştur
  MeasurementsModel copyWith({
    String? userId,
    DateTime? date,
    double? weight,
    double? height,
    double? chest,
    double? waist,
    double? hip,
    double? arm,
    double? leg,
    double? bodyFatPercentage,
    double? bmi,
    String? notes,
  }) {
    return MeasurementsModel(
      id: this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      chest: chest ?? this.chest,
      waist: waist ?? this.waist,
      hip: hip ?? this.hip,
      arm: arm ?? this.arm,
      leg: leg ?? this.leg,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      bmi: bmi ?? this.bmi,
      notes: notes ?? this.notes,
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